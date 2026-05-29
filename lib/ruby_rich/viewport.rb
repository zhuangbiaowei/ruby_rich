# frozen_string_literal: true

module RubyRich
  class Viewport
    attr_accessor :width, :height, :scroll_top
    attr_reader :content, :selected_text

    def initialize(content = "", scrollbar: true, auto_scroll: false, scrollbar_style: :blue)
      @content = content
      @scrollbar = scrollbar
      @auto_scroll = auto_scroll
      @scrollbar_style = scrollbar_style
      @width = 0
      @height = 0
      @scroll_top = 0
      @dragging_scrollbar = false
      @dragging_viewport = false
      @drag_start_y = nil
      @drag_start_scroll_top = nil
      @selecting = false
      @selection_start = nil
      @selection_end = nil
      @selected_text = ""
      @focused = true
      @rendered_lines_cache_key = nil
      @rendered_lines_cache = nil
    end

    def focus
      @focused = true
      self
    end

    def blur
      @focused = false
      self
    end

    def content=(new_content)
      was_at_bottom = at_bottom?
      @content = new_content
      invalidate_rendered_lines
      scroll_to_bottom if @auto_scroll && was_at_bottom
      clamp_scroll
    end

    def attach(layout, priority: 100)
      [:page_up, :page_down, :home, :end, :up, :down].each do |event_name|
        layout.key(event_name, priority) do |event_data, _live|
          handle_event(event_data, layout)
          false
        end
      end

      [:mouse_wheel, :mouse_down, :mouse_drag, :mouse_up].each do |event_name|
        layout.key(event_name, priority) do |event_data, _live|
          handle_event(event_data, layout)
        end
      end

      self
    end

    def handle_event(event_data, layout = nil)
      return false if keyboard_event?(event_data) && !@focused

      case event_data[:name]
      when :page_up
        scroll_by(-page_size)
        false
      when :page_down
        scroll_by(page_size)
        false
      when :home
        scroll_to(0)
        false
      when :end
        scroll_to_bottom
        false
      when :up
        scroll_by(-1)
        false
      when :down
        scroll_by(1)
        false
      when :mouse_wheel
        scroll_by(event_data[:direction] == :down ? 3 : -3)
        true
      when :mouse_down
        return copy_selection if event_data[:button] == :right

        start_scrollbar_drag(event_data, layout) || start_viewport_drag(event_data, layout)
      when :mouse_drag
        drag_scrollbar(event_data, layout) || drag_viewport(event_data, layout) || drag_selection(event_data, layout)
      when :mouse_up
        stop_scrollbar_drag || stop_viewport_drag || stop_selection
      else
        false
      end
    end

    def render
      clamp_scroll
      return [] if @height.to_i <= 0 || @width.to_i <= 0

      visible_width = content_width
      visible = rendered_lines[@scroll_top, @height] || []
      lines = Array.new(@height) { "" }

      @height.times do |index|
        absolute_line = @scroll_top + index
        lines[index] = apply_selection(fit_line(visible[index].to_s, visible_width), absolute_line)
      end

      return lines unless show_scrollbar?

      scrollbar = render_scrollbar
      lines.each_with_index.map { |line, index| line + scrollbar[index] }
    end

    def scroll_by(delta)
      scroll_to(@scroll_top + delta)
    end

    def scroll_to(line)
      @scroll_top = line.to_i
      clamp_scroll
    end

    def scroll_to_bottom
      @scroll_top = max_scroll_top
      clamp_scroll
    end

    def at_bottom?
      @scroll_top >= max_scroll_top
    end

    def max_scroll_top
      [rendered_lines.length - @height, 0].max
    end

    private

    def rendered_lines
      key = rendered_lines_cache_key(@content)
      return @rendered_lines_cache if @rendered_lines_cache_key == key && @rendered_lines_cache

      @rendered_lines_cache_key = key
      @rendered_lines_cache = normalize_lines(@content)
    end

    def invalidate_rendered_lines
      @rendered_lines_cache_key = nil
      @rendered_lines_cache = nil
    end

    def rendered_lines_cache_key(value)
      [
        value.object_id,
        content_width,
        value.respond_to?(:version) ? value.version : nil
      ]
    end

    def keyboard_event?(event_data)
      event_data[:type] == :key
    end

    def mouse_event?(event_data)
      event_data[:type] == :mouse
    end

    def normalize_lines(value)
      value.width = content_width if value.respond_to?(:width=)

      rendered = if value.respond_to?(:render)
                   value.render
                 else
                   value
                 end

      case rendered
      when String
        rendered.split("\n").flat_map { |line| wrap_display_line(line, content_width) }
      when Array
        rendered.flat_map { |line| wrap_display_line(line.to_s, content_width) }
      else
        rendered.to_s.split("\n").flat_map { |line| wrap_display_line(line, content_width) }
      end
    end

    def wrap_display_line(line, target_width)
      return [""] if line.empty?
      return [line] if display_width(line) <= target_width

      lines = []
      current = +""
      width = 0
      in_escape = false
      escape = +""
      active_sgr = +""

      line.each_char do |char|
        if in_escape
          escape << char
          if char == "m"
            current << escape
            active_sgr = escape == AnsiCode.reset ? +"" : escape.dup
            escape = +""
            in_escape = false
          end
          next
        elsif char.ord == 27
          escape << char
          in_escape = true
          next
        end

        char_width = Unicode::DisplayWidth.of(char)
        if width.positive? && width + char_width > target_width
          lines << close_wrapped_line(current, active_sgr)
          current = active_sgr.dup
          width = 0
        end

        current << char
        width += char_width
      end

      lines << current unless current.empty?
      lines.empty? ? [""] : lines
    end

    def close_wrapped_line(line, active_sgr)
      active_sgr.empty? || line.end_with?(AnsiCode.reset) ? line : "#{line}#{AnsiCode.reset}"
    end

    def page_size
      [@height - 1, 1].max
    end

    def content_width
      @scrollbar ? [@width - 1, 1].max : @width
    end

    def show_scrollbar?
      @scrollbar && @width.positive?
    end

    def render_scrollbar
      lines = Array.new(@height) { track_char }
      return lines if @height <= 0

      thumb_size.times do |offset|
        index = thumb_top + offset
        lines[index] = thumb_char if index.between?(0, @height - 1)
      end

      lines
    end

    def thumb_size
      total = rendered_lines.length
      return @height if total <= @height

      [(@height.to_f * @height / total).ceil, 1].max
    end

    def thumb_top
      total_scroll = max_scroll_top
      return 0 if total_scroll.zero?

      travel = [@height - thumb_size, 0].max
      (@scroll_top.to_f / total_scroll * travel).round
    end

    def track_char
      "#{AnsiCode.color(:black, true)}│#{AnsiCode.reset}"
    end

    def thumb_char
      "#{AnsiCode.color(@scrollbar_style, true)}│#{AnsiCode.reset}"
    end

    def fit_line(line, target_width)
      plain_width = display_width(line)
      return line + (" " * (target_width - plain_width)) if plain_width <= target_width

      truncate_display(line, target_width)
    end

    def truncate_display(line, target_width)
      result = +""
      width = 0
      in_escape = false
      escape = +""

      line.each_char do |char|
        if in_escape
          escape << char
          if char == "m"
            result << escape
            escape = +""
            in_escape = false
          end
          next
        elsif char.ord == 27
          escape << char
          in_escape = true
          next
        end

        char_width = Unicode::DisplayWidth.of(char)
        break if width + char_width > target_width

        result << char
        width += char_width
      end

      result
    end

    def display_width(line)
      line.gsub(/\e\[[0-9;:]*m/, "").chars.sum { |char| Unicode::DisplayWidth.of(char) }
    end

    def clamp_scroll
      @scroll_top = [[@scroll_top, 0].max, max_scroll_top].min
    end

    def start_scrollbar_drag(event_data, layout)
      return false unless layout
      return false unless event_data[:x] == layout.x_offset + @width - 1

      @dragging_scrollbar = true
      @drag_start_y = event_data[:y]
      @drag_start_scroll_top = @scroll_top
      scroll_to(scroll_top_for_y(event_data[:y], layout))
      true
    end

    def start_selection(event_data, layout)
      return false unless layout
      return false if event_data[:x] >= layout.x_offset + content_width
      return false unless event_data[:y].between?(layout.y_offset, layout.y_offset + @height - 1)

      @selecting = true
      @selection_start = mouse_position(event_data, layout)
      @selection_end = @selection_start
      @selected_text = ""
      true
    end

    def start_viewport_drag(event_data, layout)
      return false unless layout
      return false unless event_data[:button] == :left
      return false if event_data[:x] >= layout.x_offset + content_width
      return false unless event_data[:y].between?(layout.y_offset, layout.y_offset + @height - 1)

      @dragging_viewport = true
      @drag_start_y = event_data[:y]
      @drag_start_scroll_top = @scroll_top
      true
    end

    def drag_scrollbar(event_data, layout)
      return false unless @dragging_scrollbar && layout

      if @drag_start_y
        travel = [@height - thumb_size, 1].max
        scroll_travel = max_scroll_top
        delta_y = event_data[:y] - @drag_start_y
        scroll_to(@drag_start_scroll_top + (delta_y.to_f / travel * scroll_travel).round)
      else
        scroll_to(scroll_top_for_y(event_data[:y], layout))
      end

      true
    end

    def drag_viewport(event_data, layout)
      return false unless @dragging_viewport && layout

      delta_y = event_data[:y] - @drag_start_y
      scroll_to(@drag_start_scroll_top - delta_y)
      true
    end

    def drag_selection(event_data, layout)
      return false unless @selecting && layout

      @selection_end = mouse_position(event_data, layout)
      true
    end

    def stop_scrollbar_drag
      was_dragging = @dragging_scrollbar
      @dragging_scrollbar = false
      @drag_start_y = nil
      @drag_start_scroll_top = nil
      was_dragging
    end

    def stop_viewport_drag
      was_dragging = @dragging_viewport
      @dragging_viewport = false
      @drag_start_y = nil
      @drag_start_scroll_top = nil
      was_dragging
    end

    def stop_selection
      return false unless @selecting

      @selecting = false
      @selected_text = extract_selected_text
      copy_selection
      true
    end

    def copy_selection
      return false if @selected_text.to_s.empty?

      copy_to_clipboard(@selected_text)
      true
    end

    def scroll_top_for_y(y, layout)
      relative_y = [[y - layout.y_offset, 0].max, @height - 1].min
      travel = [@height - thumb_size, 1].max
      (relative_y.to_f / travel * max_scroll_top).round
    end

    def mouse_position(event_data, layout)
      {
        line: @scroll_top + [[event_data[:y] - layout.y_offset, 0].max, @height - 1].min,
        col: [[event_data[:x] - layout.x_offset, 0].max, content_width].min
      }
    end

    def normalized_selection
      return nil unless @selection_start && @selection_end

      a = @selection_start
      b = @selection_end
      if a[:line] < b[:line] || (a[:line] == b[:line] && a[:col] <= b[:col])
        [a, b]
      else
        [b, a]
      end
    end

    def apply_selection(line, absolute_line)
      range = normalized_selection
      return line unless range

      start_pos, end_pos = range
      return line if absolute_line < start_pos[:line] || absolute_line > end_pos[:line]

      start_col = absolute_line == start_pos[:line] ? start_pos[:col] : 0
      end_col = absolute_line == end_pos[:line] ? end_pos[:col] : content_width
      highlight_display_range(line, start_col, end_col)
    end

    def highlight_display_range(line, start_col, end_col)
      return line if end_col <= start_col

      result = +""
      width = 0
      active = false
      in_escape = false
      escape = +""

      line.each_char do |char|
        if in_escape
          escape << char
          if char == "m"
            result << escape
            escape = +""
            in_escape = false
          end
          next
        elsif char.ord == 27
          escape << char
          in_escape = true
          next
        end

        char_width = Unicode::DisplayWidth.of(char)
        should_highlight = width < end_col && width + char_width > start_col
        if should_highlight && !active
          result << AnsiCode.inverse
          active = true
        elsif !should_highlight && active
          result << AnsiCode.reset
          active = false
        end
        result << char
        width += char_width
      end
      result << AnsiCode.reset if active
      result
    end

    def extract_selected_text
      range = normalized_selection
      return "" unless range

      start_pos, end_pos = range
      (start_pos[:line]..end_pos[:line]).map do |line_index|
        line = strip_ansi(rendered_lines[line_index].to_s)
        start_col = line_index == start_pos[:line] ? start_pos[:col] : 0
        end_col = line_index == end_pos[:line] ? end_pos[:col] : display_width(line)
        slice_display_range(line, start_col, end_col).rstrip
      end.join("\n")
    end

    def slice_display_range(line, start_col, end_col)
      result = +""
      width = 0
      line.each_char do |char|
        char_width = Unicode::DisplayWidth.of(char)
        result << char if width < end_col && width + char_width > start_col
        width += char_width
      end
      result
    end

    def strip_ansi(text)
      text.gsub(/\e\[[0-9;:]*m/, "")
    end

    def copy_to_clipboard(text)
      if RubyRich::Terminal.windows?
        copy_to_windows_clipboard(text)
      elsif ENV["WAYLAND_DISPLAY"]
        IO.popen("wl-copy", "w") { |io| io.write(text) }
      elsif ENV["DISPLAY"]
        IO.popen("xclip -selection clipboard", "w") { |io| io.write(text) }
      elsif RUBY_PLATFORM.match?(/darwin/)
        IO.popen("pbcopy", "w") { |io| io.write(text) }
      end
    rescue IOError, SystemCallError
      nil
    end

    def copy_to_windows_clipboard(text)
      script = "[Console]::InputEncoding=[System.Text.UTF8Encoding]::new($false); Set-Clipboard -Value ([Console]::In.ReadToEnd())"
      IO.popen(["powershell", "-NoProfile", "-NonInteractive", "-Command", script], "w") do |io|
        io.set_encoding(Encoding::UTF_8)
        io.write(text.to_s.encode(Encoding::UTF_8))
      end
    rescue IOError, SystemCallError
      IO.popen("clip", "w") do |io|
        io.binmode
        io.write("\uFEFF".encode("UTF-16LE"))
        io.write(text.to_s.encode("UTF-16LE"))
      end
    end
  end
end
