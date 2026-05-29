# frozen_string_literal: true

module RubyRich
  class LineEditor
    WORD_PATTERN = /[^\s]+/

    attr_reader :history, :cursor
    attr_accessor :multiline, :history_path, :max_history

    def initialize(multiline: false, history: [], history_path: nil, max_history: 200)
      @multiline = multiline
      @history_path = history_path
      @max_history = max_history
      @history = []
      @history_index = nil
      @chars = []
      @cursor = 0
      @value_cache = nil
      @lines_cache = nil
      @line_starts_cache = nil
      @cursor_line_col_cache_key = nil
      @cursor_line_col_cache = nil
      load_history
      history.each { |item| add_history(item, persist: false) }
    end

    def value
      @value_cache ||= @chars.join
    end

    def value=(text)
      @chars = text.to_s.chars
      @cursor = @chars.length
      @history_index = nil
      invalidate_content_cache
      self
    end

    def empty?
      @chars.empty?
    end

    def clear
      @chars.clear
      @cursor = 0
      @history_index = nil
      invalidate_content_cache
      self
    end

    def insert(text)
      incoming = normalize_insert_text(text)
      return self if incoming.empty?

      new_chars = incoming.chars
      @chars.insert(@cursor, *new_chars)
      @cursor += new_chars.length
      @history_index = nil
      invalidate_content_cache
      self
    end

    def newline
      insert("\n") if @multiline
      self
    end

    def backspace
      return false if @cursor.zero?

      @chars.delete_at(@cursor - 1)
      @cursor -= 1
      invalidate_content_cache
      true
    end

    def delete
      return false if @cursor >= @chars.length

      @chars.delete_at(@cursor)
      invalidate_content_cache
      true
    end

    def move_left
      @cursor = [@cursor - 1, 0].max
      invalidate_cursor_cache
      self
    end

    def move_right
      @cursor = [@cursor + 1, @chars.length].min
      invalidate_cursor_cache
      self
    end

    def home
      @cursor = current_line_start
      invalidate_cursor_cache
      self
    end

    def end
      @cursor = current_line_end
      invalidate_cursor_cache
      self
    end

    def buffer_start
      @cursor = 0
      invalidate_cursor_cache
      self
    end

    def buffer_end
      @cursor = @chars.length
      invalidate_cursor_cache
      self
    end

    def move_up
      return history_previous if !@multiline || single_empty_line? || @history_index

      move_vertical(-1)
    end

    def move_down
      return history_next if !@multiline || single_empty_line? || @history_index

      move_vertical(1)
    end

    def kill_to_end
      return false if @cursor >= @chars.length

      @chars.slice!(@cursor...current_line_end)
      invalidate_content_cache
      true
    end

    def kill_to_start
      start = current_line_start
      return false if @cursor <= start

      @chars.slice!(start...@cursor)
      @cursor = start
      invalidate_content_cache
      true
    end

    def kill_word_back
      return false if @cursor.zero?

      start = previous_word_start
      @chars.slice!(start...@cursor)
      @cursor = start
      invalidate_content_cache
      true
    end

    def submit_value
      submitted = value
      add_history(submitted) unless submitted.strip.empty?
      clear
      submitted
    end

    def add_history(text, persist: true)
      item = text.to_s
      return self if item.strip.empty?

      @history.delete(item)
      @history << item
      @history.shift while @history.length > @max_history
      persist_history if persist && @history_path
      self
    end

    def lines
      @lines_cache ||= begin
        text = value
        text.empty? ? [""] : text.split("\n", -1)
      end
    end

    def cursor_line_col
      cache_key = [@cursor, @chars.length]
      return @cursor_line_col_cache if @cursor_line_col_cache_key == cache_key && @cursor_line_col_cache

      line_index = line_index_for_cursor
      @cursor_line_col_cache_key = cache_key
      @cursor_line_col_cache = [line_index, @cursor - line_starts[line_index]]
    end

    def render_lines(width:, placeholder: nil, focused: true)
      _ = focused
      content = value
      return [placeholder.to_s] if content.empty? && placeholder

      rendered = []
      lines.each do |line|
        rendered.concat(wrap_line_without_cursor(line, width))
      end
      rendered.empty? ? [""] : rendered
    end

    def cursor_visual_position(width:)
      line_index, cursor_col = cursor_line_col
      row = 0

      lines.each_with_index do |line, index|
        if index == line_index
          cursor_row, display_col = cursor_position_in_wrapped_line(line, width, cursor_col)
          return [row + cursor_row, display_col]
        end

        row += wrap_line_without_cursor(line, width).length
      end

      [row, 0]
    end

    private

    def invalidate_content_cache
      @value_cache = nil
      @lines_cache = nil
      @line_starts_cache = nil
      invalidate_cursor_cache
    end

    def invalidate_cursor_cache
      @cursor_line_col_cache_key = nil
      @cursor_line_col_cache = nil
    end

    def normalize_insert_text(text)
      incoming = text.to_s.gsub(/\r\n?/, "\n")
      return incoming if @multiline

      incoming.gsub(/\n/, " ")
    end

    def current_line_start
      line_starts[line_index_for_cursor]
    end

    def current_line_end
      line_index = line_index_for_cursor
      next_start = line_starts[line_index + 1]
      next_start ? next_start - 1 : @chars.length
    end

    def move_vertical(delta)
      current_line, current_col = cursor_line_col
      target_line = current_line + delta
      return self if target_line.negative? || target_line >= lines.length

      @cursor = index_for_line_col(target_line, current_col)
      invalidate_cursor_cache
      self
    end

    def index_for_line_col(line_index, col)
      line_start = line_starts[line_index]
      return @chars.length unless line_start

      line_length = lines[line_index].chars.length
      line_start + [col, line_length].min
    end

    def line_starts
      @line_starts_cache ||= begin
        starts = [0]
        @chars.each_with_index do |char, index|
          starts << index + 1 if char == "\n"
        end
        starts
      end
    end

    def line_index_for_cursor
      starts = line_starts
      low = 0
      high = starts.length - 1

      while low <= high
        mid = (low + high) / 2
        if starts[mid] <= @cursor
          low = mid + 1
        else
          high = mid - 1
        end
      end

      [high, 0].max
    end

    def previous_word_start
      index = @cursor
      index -= 1 while index.positive? && whitespace?(@chars[index - 1])
      index -= 1 while index.positive? && !whitespace?(@chars[index - 1])
      index
    end

    def whitespace?(char)
      char.to_s.match?(/\s/)
    end

    def single_empty_line?
      value.empty?
    end

    def history_previous
      return self if @history.empty?

      @history_index = @history_index ? [@history_index - 1, 0].max : @history.length - 1
      self.value = @history[@history_index]
      @history_index = @history.index(value)
      self
    end

    def history_next
      return self unless @history_index

      @history_index += 1
      if @history_index >= @history.length
        clear
      else
        self.value = @history[@history_index]
        @history_index = @history.index(value)
      end
      self
    end

    def load_history
      return unless @history_path && File.file?(@history_path)

      File.readlines(@history_path, chomp: true).each { |line| add_history(line, persist: false) }
    rescue IOError, SystemCallError
      nil
    end

    def persist_history
      File.write(@history_path, @history.join("\n") + "\n")
    rescue IOError, SystemCallError
      nil
    end

    def wrap_line_without_cursor(line, width)
      width = [width, 1].max
      segments = []
      current = +""
      current_width = 0

      line.chars.each do |char|
        char_width = display_width(char)
        if current_width + char_width > width && !current.empty?
          segments << current
          current = +""
          current_width = 0
        end

        current << char
        current_width += char_width
      end

      segments << current
      segments
    end

    def cursor_position_in_wrapped_line(line, width, cursor_col)
      width = [width, 1].max
      row = 0
      display_col = 0

      line.chars.each_with_index do |char, index|
        char_width = display_width(char)
        if display_col + char_width > width && display_col.positive?
          row += 1
          display_col = 0
        end

        return [row, display_col] if index == cursor_col

        display_col += char_width
      end

      [row, display_col]
    end

    def display_width(char)
      Unicode::DisplayWidth.of(char)
    end
  end
end
