# frozen_string_literal: true

module RubyRich
  class Viewport
    attr_accessor :width, :height, :scroll_top
    attr_reader :content

    def initialize(content = "", scrollbar: true, auto_scroll: false, scrollbar_style: :blue)
      @content = content
      @scrollbar = scrollbar
      @auto_scroll = auto_scroll
      @scrollbar_style = scrollbar_style
      @width = 0
      @height = 0
      @scroll_top = 0
      @dragging_scrollbar = false
      @drag_start_y = nil
      @drag_start_scroll_top = nil
      @focused = true
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
      return false if mouse_event?(event_data) && !@focused

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
        start_scrollbar_drag(event_data, layout)
      when :mouse_drag
        drag_scrollbar(event_data, layout)
      when :mouse_up
        stop_scrollbar_drag
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
        lines[index] = fit_line(visible[index].to_s, visible_width)
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
      @rendered_lines = normalize_lines(@content)
    end

    def keyboard_event?(event_data)
      event_data[:type] == :key
    end

    def mouse_event?(event_data)
      event_data[:type] == :mouse
    end

    def normalize_lines(value)
      rendered = if value.respond_to?(:render)
                   value.render
                 else
                   value
                 end

      case rendered
      when String
        rendered.split("\n")
      when Array
        rendered
      else
        rendered.to_s.split("\n")
      end
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

    def stop_scrollbar_drag
      was_dragging = @dragging_scrollbar
      @dragging_scrollbar = false
      @drag_start_y = nil
      @drag_start_scroll_top = nil
      was_dragging
    end

    def scroll_top_for_y(y, layout)
      relative_y = [[y - layout.y_offset, 0].max, @height - 1].min
      travel = [@height - thumb_size, 1].max
      (relative_y.to_f / travel * max_scroll_top).round
    end
  end
end
