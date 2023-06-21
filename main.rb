#!/bin/env ruby
require 'optparse'

require 'curses'

class Cursor
  def initialize(scr)
    @scr = scr
    @x   = 0
    @y   = 0
  end

  def update
    @scr.setpos @y, @x
  end

  def move(y: 0, x: 0)
    @y = wrap(@y + y, 0, @scr.maxy)
    @x = wrap(@x + x, 0, @scr.maxx)
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
  cursor = Cursor.new(stdscr)

  Curses.curs_set 2                     # Make cursor visible.
  Curses.cbreak                         # Disable input buffering.
  Curses.noecho                         # Disable input echoing.
  stdscr.keypad true                    # Enable terminal keypad.

  File.open(filename, 'r+') do |file|
    file.each do |line|
      break if stdscr.cury >= stdscr.maxy - 1 or stdscr.curx != 0

      stdscr.addstr line
    end

    while true
      cursor.update

      c = stdscr.getch

      case
      when c == 'q'
        break
      when c == Curses::Key::LEFT
        cursor.move x: -1
      when c == Curses::Key::RIGHT
        cursor.move x: 1
      when c == Curses::Key::UP
        cursor.move y: -1
      when c == Curses::Key::DOWN
        cursor.move y: 1
      end
    end
  end
end
