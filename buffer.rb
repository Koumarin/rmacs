class Buffer
  def initialize(path:)
    @file  = File.open(path, 'r+')
    @lines = []
    @dirty = false
    @path  = File.absolute_path @file.path

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
    @dirty = true
  end

  def split_line(x:, y:)
    new_line = @lines[y][x..(line_size y)]

    @lines[y] = @lines[y][0, x] + "\n"
    @lines.insert y + 1, new_line
    @dirty = true
  end

  def delete(x:, y:)
    if x < (line_size y)
      @lines[y].slice! x
    end

    ## If we deleted the end of line, we remove the new line.
    if x >= (line_size y) - 1
      @lines[y] += @lines[y + 1]
      @lines.delete_at y + 1
    end

    @dirty = true
  end

  def save
    @file.truncate 0                    # Delete all file content,
    @file.rewind                        # rewind to prevent writing null bytes
    @lines.each do |line|               # and then write each line from
      @file.write line                  # the buffer to the file.
    end

    @file.flush
    @dirty = false
  end

  def each_with_index
    @lines.each_with_index do |line, idx|
      yield line, idx
    end
  end

  ### Queries
  def bottom
    @lines.size - 1
  end

  def line_size(y)
    @lines[y].size
  end

  def name
    @file.path
  end

  def path
    @path
  end

  def dirty?
    @dirty
  end
end
