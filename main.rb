#!/bin/env ruby
require 'optparse'

require 'ctype'
require 'curses'

require_relative 'buffer'
require_relative 'mini_buffer'
require_relative 'window'

def with_curses
  yield Curses.stdscr
ensure
  Curses.close_screen
end

def ctrl_key c
 if c.is_a? String
   c.codepoints[0] & 0x1f
 else
   c & 0x1f
 end
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
  mini = MiniBuffer.new screen: stdscr

  Curses.curs_set 2                     # Make cursor visible.
  Curses.cbreak                         # Disable input buffering.
  Curses.noecho                         # Disable input echoing.
  Curses.raw                            # Don't generate signals on ctrl chars.
  stdscr.keypad true                    # Enable terminal keypad.

  loop do
    window.draw

    c = stdscr.getch

    mini.clear

    case
    when c ==  Curses::Key::LEFT
      window.move x: -1
    when c == Curses::Key::RIGHT
      window.move x: 1
    when c == Curses::Key::UP
      window.move y: -1
    when c == Curses::Key::DOWN
      window.move y: 1
    when c == (ctrl_key 'j')
      window.split_line
    when c == Curses::Key::BACKSPACE
      window.backspace
    when c == Curses::Key::DC           # Delete character.
      window.delete
    ## Control characters:
    when c == (ctrl_key 'c')
      break
    when c == (ctrl_key 's')
      window.save
    when c == (ctrl_key 'f')
      window.prompt_open
    when c == (ctrl_key 'z')
      Process.kill :TSTP, Process.pid
    when c.print?
      window.insert c
    else
      raise "#{c}"
    end
  end
end
