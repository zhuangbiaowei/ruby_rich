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
      load_history
      history.each { |item| add_history(item, persist: false) }
    end

    def value
      @chars.join
    end

    def value=(text)
      @chars = text.to_s.chars
      @cursor = @chars.length
      @history_index = nil
      self
    end

    def empty?
      @chars.empty?
    end

    def clear
      @chars.clear
      @cursor = 0
      @history_index = nil
      self
    end

    def insert(text)
      incoming = normalize_insert_text(text)
      return self if incoming.empty?

      new_chars = incoming.chars
      @chars.insert(@cursor, *new_chars)
      @cursor += new_chars.length
      @history_index = nil
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
      true
    end

    def delete
      return false if @cursor >= @chars.length

      @chars.delete_at(@cursor)
      true
    end

    def move_left
      @cursor = [@cursor - 1, 0].max
      self
    end

    def move_right
      @cursor = [@cursor + 1, @chars.length].min
      self
    end

    def home
      @cursor = current_line_start
      self
    end

    def end
      @cursor = current_line_end
      self
    end

    def buffer_start
      @cursor = 0
      self
    end

    def buffer_end
      @cursor = @chars.length
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
      true
    end

    def kill_to_start
      start = current_line_start
      return false if @cursor <= start

      @chars.slice!(start...@cursor)
      @cursor = start
      true
    end

    def kill_word_back
      return false if @cursor.zero?

      start = previous_word_start
      @chars.slice!(start...@cursor)
      @cursor = start
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
      text = value
      text.empty? ? [""] : text.split("\n", -1)
    end

    def cursor_line_col
      before = @chars[0...@cursor].join
      parts = before.empty? ? [""] : before.split("\n", -1)
      [parts.length - 1, parts.last.to_s.chars.length]
    end

    def render_lines(width:, placeholder: nil, focused: true)
      content = value
      return [placeholder.to_s] if content.empty? && placeholder

      rendered = []
      line_index, col = cursor_line_col
      lines.each_with_index do |line, index|
        marker_col = focused && index == line_index ? col : nil
        rendered.concat(wrap_line_with_cursor(line, width, marker_col))
      end
      rendered.empty? ? [""] : rendered
    end

    private

    def normalize_insert_text(text)
      incoming = text.to_s.gsub(/\r\n?/, "\n")
      return incoming if @multiline

      incoming.gsub(/\n/, " ")
    end

    def current_line_start
      index = @cursor - 1
      while index >= 0
        return index + 1 if @chars[index] == "\n"

        index -= 1
      end
      0
    end

    def current_line_end
      index = @cursor
      while index < @chars.length
        return index if @chars[index] == "\n"

        index += 1
      end
      @chars.length
    end

    def move_vertical(delta)
      current_line, current_col = cursor_line_col
      target_line = current_line + delta
      return self if target_line.negative? || target_line >= lines.length

      @cursor = index_for_line_col(target_line, current_col)
      self
    end

    def index_for_line_col(line_index, col)
      index = 0
      lines.each_with_index do |line, current|
        line_length = line.chars.length
        return index + [col, line_length].min if current == line_index

        index += line_length + 1
      end
      @chars.length
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

    def wrap_line_with_cursor(line, width, marker_col)
      width = [width, 1].max
      segments = []
      current = +""
      current_width = 0
      chars = line.chars
      chars.each_with_index do |char, index|
        if marker_col == index
          cursor = cursor_marker
          if current_width + 1 > width
            segments << current
            current = +""
            current_width = 0
          end
          current << cursor
          current_width += 1
        end

        char_width = display_width(char)
        if current_width + char_width > width
          segments << current
          current = +""
          current_width = 0
        end
        current << char
        current_width += char_width
      end

      current << cursor_marker if marker_col == chars.length
      segments << current
      segments
    end

    def cursor_marker
      "#{AnsiCode.color(:blue, true)}_#{AnsiCode.reset}"
    end

    def display_width(char)
      Unicode::DisplayWidth.of(char)
    end
  end
end
