#!/bin/env ruby
require 'optparse'

require 'curses'

class Buffer
  def initialize(path:)
    @file  = File.open(path, 'r+')
    @lines = []
    @y     = 0
    @x     = 0

    @file.each do |line|
      @lines.push line
    end

    ## Add an empty line to empty documents.
    if @lines.size == 0
      @lines.push ' '
    end
  end

  def insert(c)
    x = @x.clamp 0, @lines[@y].size - 1

    @lines[@y][@x] = c
    @lines[@y] += "\n" if @x == @lines[@y].size - 1
    @x += 1
  end

  def split_line
    new_line   = @lines[@y][@x..@lines[@y].size]

    @lines[@y] = @lines[@y][0, @x] + "\n"
    @lines.insert @y + 1, new_line

    move x: -@x, y: 1
  end

  def delete(offset: 0)
    x = @x + offset

    @lines[@y].slice! x
    @x += offset

    if x >= @lines[@y].size - 1
      @lines[@y] += @lines[@y + 1]
      @lines.delete_at @y + 1
    end
  end

  def move(x: 0, y: 0)
    @y  = (@y + y).clamp 0, @lines.size - 1
    @x += x

    if x != 0
      case
      when @x >= @lines[@y].size
        @y = (@y + 1).clamp 0, @lines.size - 1
        @x = 0
      when @x < 0
        @y = (@y - 1).clamp 0, @lines.size - 1
        @x = @lines[@y].size - 1
      end
    end
  end

  def draw(to:)
    ## We want to scroll the buffer until the current cursor is in the screen.
    off  = 0
    off += to.maxy while @y - off >= to.maxy
    stop = to.maxy + off

    to.setpos 0, 0
    to.erase

    @lines.each_with_index do |line, idx|
      next  if idx <  off
      break if idx >= stop

      to.addstr line
    end

    to.setpos (@y - off).clamp(0, to.maxy),
              @x.clamp(0, @lines[@y].size - 1)
  end
end

def with_curses
  yield Curses.stdscr
ensure
  Curses.close_screen
end

OptionParser.new do |parser|
  parser.banner = 'Usage: rmacs [file]'
end.parse!

if ARGV.size != 1
  puts 'Please name a file to edit.'
  exit
end

filename = ARGV.first

with_curses do |stdscr|
  buffer = Buffer.new path: filename

  Curses.curs_set 2                     # Make cursor visible.
  Curses.cbreak                         # Disable input buffering.
  Curses.noecho                         # Disable input echoing.
  stdscr.keypad true                    # Enable terminal keypad.

  loop do
    buffer.draw to: stdscr

    c = stdscr.getch

    case c
    when Curses::Key::LEFT
      buffer.move x: -1
    when Curses::Key::RIGHT
      buffer.move x: 1
    when Curses::Key::UP
      buffer.move y: -1
    when Curses::Key::DOWN
      buffer.move y: 1
    when 10
      buffer.split_line
    when Curses::Key::BACKSPACE
      buffer.delete offset: -1
    when 330                            # Delete
      buffer.delete
    else
      buffer.insert c
    end
  end
end
