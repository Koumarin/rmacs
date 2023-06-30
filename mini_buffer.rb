class MiniBuffer
  def initialize(screen:)
    @curses_window = screen.subwin 1, screen.maxx, screen.maxy - 1, 0
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
end
