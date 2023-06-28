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

  ### Queries
  def height
    @curses_window.maxy
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
end
