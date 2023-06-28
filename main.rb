#!/bin/env ruby
require 'optparse'

require 'curses'

class Buffer
  def initialize(path:)
    @file  = File.open(path, 'r+')
    @lines = []

    @file.each do |line|
      @lines.push line
    end

    ## Add an empty line to empty documents.
    if @lines.size == 0
      @lines.push ' '
    end
  end

  def insert(c, x:, y:)
    x = x.clamp 0, (line_size y) - 1

    @lines[y].insert x, c
  end

  def split_line(x:, y:)
    new_line = @lines[y][x..(line_size y)]

    @lines[y] = @lines[y][0, x] + "\n"
    @lines.insert y + 1, new_line
  end

  def delete(x:, y:)
    @lines[y].slice! x

    ## If we deleted the end of line, we remove the new line.
    if x >= (line_size y) - 1
      @lines[y] += @lines[y + 1]
      @lines.delete_at y + 1
    end
  end

  def save
    @file.truncate 0                    # Delete all file content,
    @file.rewind                        # rewind to prevent writing null bytes
    @lines.each do |line|               # and then write each line from
      @file.write line                  # the buffer to the file.
    end

    @file.flush
  end

  def each_with_index
    @lines.each_with_index do |line, idx|
      yield line, idx
    end
  end

  def bottom
    @lines.size - 1
  end

  def line_size(y)
    @lines[y].size
  end
end

class Window
  def initialize(screen:, buffer:)
    ##                                 height          width     y  x
    @curses_window = screen.subwin screen.maxy - 1, screen.maxx, 0, 0
    @buffer        = buffer
    @y, @x         = 0, 0
  end

  def move(x: 0, y: 0)
    @y  = (@y + y).clamp 0, @buffer.bottom
    @x += x

    if x != 0
      case
      when @x >= (@buffer.line_size @y)
        @y = (@y + 1).clamp 0, @buffer.bottom
        @x = 0
      when @x < 0
        @y = (@y - 1).clamp 0, @buffer.bottom
        @x = (@buffer.line_size @y) - 1
      end
    end
  end

  def insert(c)
    @buffer.insert c, x: @x, y: @y
    move x: 1
  end

  def split_line
    @buffer.split_line x: @x, y: @y

    move x: -@x, y: 1
  end

  def backspace
    unless @y == 0 and @x == 0
      move x: -1
      @buffer.delete x: @x, y: @y
    end
  end

  def delete
    @buffer.delete x: @x, y: @y
  end

  def draw
    return if not @buffer

    ## We want to scroll the buffer until the current cursor is in the screen.
    off  = 0
    off += height while @y - off >= height
    stop = height + off

    @curses_window.setpos 0, 0
    @curses_window.erase

    @buffer.each_with_index do |line, idx|
      next  if idx <  off
      break if idx >= stop

      @curses_window.addstr line
    end

    @curses_window.setpos (@y - off).clamp(0, height),
                          @x.clamp(0, (@buffer.line_size @y) - 1)

    @curses_window.refresh
  end

  def save
    @buffer.save
  end

  def height
    @curses_window.maxy
  end

  def width
    @curses_window.maxx
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
  window = Window.new screen: stdscr,
                      buffer: (Buffer.new path: filename)

  Curses.curs_set 2                     # Make cursor visible.
  Curses.cbreak                         # Disable input buffering.
  Curses.noecho                         # Disable input echoing.
  Curses.raw                            # Don't generate signals on ctrl chars.
  stdscr.keypad true                    # Enable terminal keypad.

  loop do
    window.draw

    c = stdscr.getch

    case c
    when Curses::Key::LEFT
      window.move x: -1
    when Curses::Key::RIGHT
      window.move x: 1
    when Curses::Key::UP
      window.move y: -1
    when Curses::Key::DOWN
      window.move y: 1
    when 10
      window.split_line
    when Curses::Key::BACKSPACE
      window.backspace
    when Curses::Key::DC                # Delete character.
      window.delete
    ## Control characters:
    when 3                              # C-c
      break
    when 19                             # C-s
      window.save
    else
      window.insert c
    end
  end
end
