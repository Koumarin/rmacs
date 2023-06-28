class Window
  def initialize(screen:, buffer:)
    ##                                 height          width     y  x
    @curses_window = screen.subwin screen.maxy - 1, screen.maxx, 0, 0
    @mode_line     = ModeLine.new parent: @curses_window, window: self
    @buffer        = buffer
    @y, @x         = 0, 0
  end

  def move(x: 0, y: 0)
    @y  = (@y + y).clamp 0, @buffer.bottom
    @x += x

    if x != 0
      case
      when @x >= (@buffer.line_size @y)
        if @y == @buffer.bottom
          @x = (@buffer.line_size @y) - 1
        else
          @y = (@y + 1).clamp 0, @buffer.bottom
          @x = 0
        end
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

    @mode_line.draw

    @curses_window.setpos (@y - off).clamp(0, height),
                          @x.clamp(0, (@buffer.line_size @y) - 1)

    @curses_window.refresh
  end

  def save
    @buffer.save
  end

  ### Queries
  def height
    @curses_window.maxy - 1
  end

  def width
    @curses_window.maxx
  end

  def position
    [@y, @x]
  end

  def path
    @buffer.path
  end

  def dirty?
    @buffer.dirty?
  end
end

class ModeLine
  def initialize(parent:, window:)
    ##                             h     width           y          x
    @curses_window = parent.subwin 1, parent.maxx, parent.maxy - 1, 0
    @window        = window
  end

  def draw
    y, x = @window.position
    @curses_window.erase
    @curses_window.addstr @window.dirty? ? '** ' : '-- '
    @curses_window.addstr @window.path + ' '
    @curses_window.addstr "(#{y + 1},#{x})"
    @curses_window.refresh
  end
end
