module RubyRich
  class Layout
    attr_accessor :name, :ratio, :size, :children, :content, :parent, :live, :dialog
    attr_accessor :x_offset, :y_offset, :width, :height, :show
    attr_reader :split_direction

    def initialize(name: nil, ratio: 1, size: nil, width: nil, height: nil)
      @name = name
      @ratio = ratio
      @size = size
      @children = []
      @content = nil
      @parent = nil
      @x_offset = 0
      @y_offset = 0
      @width = width if width
      @height = height if height
      @split_direction = nil
      @show = true
      @event_listeners = {}
      @event_intercepted = false
      @mouse_capture = nil
    end

    def key(event_name, priority = 0, &block)
      unless @event_listeners[event_name]
        @event_listeners[event_name] = []
      end
      @event_listeners[event_name] << { priority: priority, block: block }
      @event_listeners[event_name].sort_by! { |l| -l[:priority] } # Higher priority first
    end

    def show=(flag)
      @show = flag
      @event_intercepted = !flag
    end

    def notify_listeners(event_data)
      return route_mouse_event(event_data) if event_data[:type] == :mouse

      return if @event_intercepted
      if @dialog
        @dialog.notify_listeners(event_data)
      else
        event_name = event_data[:name]
        if @event_listeners[event_name]
          @event_listeners[event_name].each do |listener|
            next if @event_intercepted
            result = listener[:block].call(event_data, self.root.live)
            if result == true
              @event_intercepted = true
            end
          end
        end
        
        unless @event_intercepted
          @children.each do |child|
            child.notify_listeners(event_data)
          end
        end
      end
    end

    def root
      @parent ? @parent.root : self
    end

    def contains?(x, y)
      return false unless @show
      return false unless @width && @height

      x >= @x_offset &&
        x < @x_offset + @width &&
        y >= @y_offset &&
        y < @y_offset + @height
    end

    def hit_test(x, y)
      return nil unless contains?(x, y)

      @children.reverse_each do |child|
        hit = child.hit_test(x, y)
        return hit if hit
      end

      self
    end

    def split_row(*layouts)
      @split_direction = :row
      layouts.each { |l| l.parent = self }
      @children.concat(layouts)
    end

    def split_column(*layouts)
      @split_direction = :column
      layouts.each { |l| l.parent = self }
      @children.concat(layouts)
    end

    def add_child(layout)
      layout.parent = self
      @children << layout
    end

    def update_content(content)
      @content = content
    end

    def calculate_dimensions(terminal_width, terminal_height)
      @x_offset = 0
      @y_offset = 0
      calculate_node_dimensions(terminal_width, terminal_height)
    end

    def [](name)
      find_by_name(name)
    end
    
    def find_by_name(name)
      return self if @name == name
      @children.each do |child|
        result = child.find_by_name(name)
        return result if result
      end
      nil
    end

    def show_dialog(dialog)
      @dialog = dialog
    end

    def hide_dialog
      @dialog.notify_listeners({:name=>:close})
      @dialog = nil
    end

    def render
      # Convert buffer to string (join lines with newlines)
      buffer = render_to_buffer
      buffer.map { |line| line.compact.join("") }.join("\n")
    end

    def render_to_buffer
      # Initialize buffer (2D array, each element represents a character)
      buffer = Array.new(@height) { Array.new(@width, " ") }
      # Recursively fill content into buffer
      render_into(buffer)
      render_dialog_into(buffer) if @dialog
      return buffer
    end

    def draw
      puts render
    end

    def render_dialog_into(buffer)
      start_x = (@width - 2 - @dialog.width) / 2 + 1
      start_y = (@height - 2 - @dialog.height) / 2 + 1
      dialog_buffer = @dialog.render_to_buffer
      buffer.each_with_index do |arr, y|
        arr.each_with_index do |char, x|          
          if x >= start_x && y >= start_y
            if y-start_y <= dialog_buffer.size-1 && x-start_x <= dialog_buffer[y-start_y].size-1
              buffer[y][x] = dialog_buffer[y-start_y][x-start_x]
            end
          end
        end
      end
    end

    def render_into(buffer)
      children.each { |child| child.render_into(buffer) } if children
      return unless content
      content_lines = if content.is_a?(String)
                        content.split("\n")[0...height]
                      else
                        normalize_rendered_lines(content.render)[0...height]
                      end
    
      content_lines.each_with_index do |line, line_index|
        y_pos = y_offset + line_index
        next if y_pos >= buffer.size
    
        in_escape = false
        escape_char = ""
        char_width = 0 # Initialize width to 0 for position calculation
        line.each_char do |char|
          # Handle ANSI escape codes
          if in_escape
            escape_char += char
            in_escape = false if char == 'm'
            if escape_char=="\e[0m"
              escape_char = ""
            end
            next
          elsif char.ord == 27 # Detect escape sequence start \e
            in_escape = true
            escape_char += char
            next
          end

          # Calculate character width
          char_w = case char.ord
                   when 0x0000..0x007F then 1 # English characters
                   when 0x4E00..0x9FFF then 2 # Chinese characters
                   else Unicode::DisplayWidth.of(char)
                   end
          # Calculate character start position
          x_start = x_offset + char_width

          # Skip if beyond right boundary
          next if x_start >= buffer[y_pos].size

          # Handle character rendering (Chinese characters may occupy multiple positions)
          char_w.times do |i|
            x_pos = x_start + i
            break if x_pos >= buffer[y_pos].size # Stop at right boundary
            unless escape_char.empty?
              char = escape_char + char + "\e[0m" # Record character's actual color each time
            end
            buffer[y_pos][x_pos] = char unless i > 0 # Write Chinese character only at first position to avoid overwriting
            buffer[y_pos][x_pos+1] = nil if char_w == 2
          end
          char_width += char_w # Update cumulative width
        end
      end
    end

    def calculate_node_dimensions(available_width, available_height)
      @width = if @size && @parent&.split_direction == :row
                 [@size, available_width].min
               else
                 available_width
               end

      @height = if @size && @parent&.split_direction == :column
                  [@size, available_height].min
                else
                  available_height
                end

      if @content.class == RubyRich::Panel
        @content.width = @width
        @content.height = @height
      else
        @content.width = @width if @content.respond_to?(:width=)
        @content.height = @height if @content.respond_to?(:height=)
      end

      return if @children.empty?

      @children.each do |child|
        next unless child.content.respond_to?(:desired_height)
        next unless @split_direction == :column

        child.size = [[child.content.desired_height, 1].max, available_height - 2].min
      end

      case @split_direction
      when :row
        remaining_width = @width
        fixed_children, flexible_children = @children.partition { |c| c.size }

        fixed_children.each do |child|
          child_width = [child.size, remaining_width].min
          child.width = child_width
          remaining_width -= child_width
        end

        total_ratio = flexible_children.sum(&:ratio)
        if total_ratio > 0
          ratio_width = remaining_width.to_f / total_ratio
          flexible_children.each do |child|
            child_width = (child.ratio * ratio_width).floor
            child.width = child_width
            remaining_width -= child_width
          end

          flexible_children.last.width += remaining_width if remaining_width > 0
        end

        @children.each { |child| child.height = @height }

        current_x = @x_offset
        @children.each do |child|
          child.x_offset = current_x
          child.y_offset = @y_offset
          current_x += child.width
          child.calculate_node_dimensions(child.width, child.height)
        end

      when :column
        remaining_height = @height
        fixed_children, flexible_children = @children.partition { |c| c.size }

        fixed_children.each do |child|
          child_height = [child.size, remaining_height].min
          child.height = child_height
          remaining_height -= child_height
        end

        total_ratio = flexible_children.sum(&:ratio)
        if total_ratio > 0
          ratio_height = remaining_height.to_f / total_ratio
          flexible_children.each do |child|
            child_height = (child.ratio * ratio_height).floor
            child.height = child_height
            remaining_height -= child_height
          end

          flexible_children.last.height += remaining_height if remaining_height > 0
        end

        @children.each { |child| child.width = @width }

        current_y = @y_offset
        @children.each do |child|
          child.x_offset = @x_offset
          child.y_offset = current_y
          current_y += child.height
          child.calculate_node_dimensions(child.width, child.height)
        end
      end
    end

    private

    def route_mouse_event(event_data)
      if @dialog
        @dialog.notify_listeners(event_data)
        return
      end

      capture = root.instance_variable_get(:@mouse_capture)
      target = capture && [:mouse_drag, :mouse_up].include?(event_data[:name]) ? capture : (hit_test(event_data[:x], event_data[:y]) || self)
      handled = target.bubble_mouse_event(event_data)

      root.instance_variable_set(:@mouse_capture, target) if event_data[:name] == :mouse_down && handled
      root.instance_variable_set(:@mouse_capture, nil) if event_data[:name] == :mouse_up
      handled
    end

    protected

    def bubble_mouse_event(event_data)
      current = self
      while current
        return true if current.dispatch_event_listeners(event_data)

        current = current.parent
      end

      false
    end

    def dispatch_event_listeners(event_data)
      listeners = @event_listeners[event_data[:name]]
      return false unless listeners

      listeners.each do |listener|
        result = listener[:block].call(event_data, root.live)
        return true if result == true
      end

      false
    end

    private

    def normalize_rendered_lines(rendered)
      case rendered
      when String
        rendered.split("\n")
      when Array
        rendered
      else
        rendered.to_s.split("\n")
      end
    end
  end
end
