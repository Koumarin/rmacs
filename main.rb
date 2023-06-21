#!/bin/env ruby
require 'optparse'

require 'curses'

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
  Curses.curs_set 2                     # Make cursor visible.

  File.open(filename, 'r+') do |file|
    file.each do |line|
      break if stdscr.cury >= stdscr.maxy or stdscr.curx != 0

      stdscr.addstr line
    end

    while true
      c = stdscr.getch

      case
      when c == 'q'
        break
      end
    end
  end
end
