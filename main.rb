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
  end

  def move(x: 0, y: 0)
    @y  = wrap(@y + y, 0, @lines.size)
    @x += x

    ## Keep current column if we only moved to a new line.
    if x != 0 and @x >= @lines[@y].size
      @y = wrap(@y + 1, 0, @lines.size)
      @x = 0
    end
  end

  def draw(to:)
    to.setpos 0, 0

    @lines.each_with_index do |line, idx|
      break if idx >= to.maxy

      to.addstr line
    end

    to.setpos wrap(@y, 0, to.maxy),
              wrap(@x, 0, @lines[@y].size)
  end

  private
  def wrap(n, min, max)
    case
    when n < min
      min
    when n >= max - 1
      max - 1
    else
      n
    end
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

    case
    when c == 'q'
      break
    when c == Curses::Key::LEFT
      buffer.move x: -1
    when c == Curses::Key::RIGHT
      buffer.move x: 1
    when c == Curses::Key::UP
      buffer.move y: -1
    when c == Curses::Key::DOWN
      buffer.move y: 1
    end
  end
end
