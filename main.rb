#!/bin/env ruby
require 'optparse'

require 'curses'

require_relative 'buffer'
require_relative 'window'

class ModeLine
  attr_writer :active_window

  def initialize(screen:)
    ##                             h     width           y          x
    @curses_window = screen.subwin 1, screen.maxx, screen.maxy - 1, 0
  end

  def draw
    y, x = @active_window.position
    @curses_window.erase
    @curses_window.addstr @active_window.dirty? ? '** ' : '-- '
    @curses_window.addstr @active_window.path + ' '
    @curses_window.addstr "(#{y + 1},#{x})"
    @curses_window.refresh
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
  line = ModeLine.new screen: stdscr

  line.active_window = window

  Curses.curs_set 2                     # Make cursor visible.
  Curses.cbreak                         # Disable input buffering.
  Curses.noecho                         # Disable input echoing.
  Curses.raw                            # Don't generate signals on ctrl chars.
  stdscr.keypad true                    # Enable terminal keypad.

  loop do
    line.draw
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
