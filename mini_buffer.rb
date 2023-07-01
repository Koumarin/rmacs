require 'curses'
require 'wisper'

class MiniBuffer
  def initialize(screen:)
    @curses_window = screen.subwin 1, screen.maxx, screen.maxy - 1, 0

    Wisper.subscribe self
  end

  def clear
    @curses_window.erase
    @curses_window.refresh
  end

  ## Signals
  def log_to_minibuffer(text)
    @curses_window.setpos 0, 0
    @curses_window.addstr text
    @curses_window.refresh
  end

  def prompt_in_minibuffer(window, prompt, method)
    Curses.echo

    @curses_window.addstr prompt
    response = @curses_window.getstr
    window.send method, response

    @curses_window.erase
    @curses_window.refresh
    Curses.noecho
  end
end
