module RubyRich
  class Layout
    attr_accessor :name, :ratio, :size, :children, :content, :parent, :x_offset, :y_offset, :width, :height
    attr_reader :split_direction

    def initialize(name: nil, ratio: 1, size: nil)
      @name = name
      @ratio = ratio
      @size = size
      @children = []
      @content = nil
      @parent = nil
      @x_offset = 0
      @y_offset = 0
      @width = nil
      @height = nil
      @split_direction = nil
    end

    def root
      @parent ? @parent.root : self
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

    def render
      # 将缓冲区转换为字符串（每行用换行符连接）
      render_to_buffer.map { |line| line.compact.join("") }.join("\n")
    end

    def render_to_buffer
      # 初始化缓冲区（二维数组，每个元素代表一个字符）
      buffer = Array.new(@height) { Array.new(@width, " ") }
      
      # 递归填充内容到缓冲区
      render_into(buffer)

      return buffer
    end

    def draw
      puts render
    end

    def render_into(buffer)
      children.each { |child| child.render_into(buffer) } if children
      return unless content
      content_lines = if content.is_a?(String)
                        content.split("\n")[0...height]
                      else
                        content.render[0...height]
                      end
    
      content_lines.each_with_index do |line, line_index|
        y_pos = y_offset + line_index
        next if y_pos >= buffer.size
    
        in_escape = false
        escape_char = ""
        char_width = 0 # 初始宽度调整为0，方便位置计算
        line.each_char do |char|
          # 处理ANSI转义码
          if in_escape
            escape_char += char
            in_escape = false if char == 'm'
            if escape_char=="\e[0m"
              escape_char = ""
            end
            next
          elsif char.ord == 27 # 检测到转义开始符\e
            in_escape = true
            escape_char += char
            next
          end
    
          # 计算字符宽度
          char_w = case char.ord
                   when 0x0000..0x007F then 1 # 英文字符
                   when 0x4E00..0x9FFF then 2 # 中文字符
                   else Unicode::DisplayWidth.of(char)
                   end
          # 计算字符的起始位置
          x_start = x_offset + char_width
    
          # 超出右边界则跳过
          next if x_start >= buffer[y_pos].size
    
          # 处理字符渲染（中文字符可能占用多个位置）
          char_w.times do |i|
            x_pos = x_start + i
            break if x_pos >= buffer[y_pos].size # 超出右边界停止
            unless escape_char.empty?
              char = escape_char + char + "\e[0m" # 每次都记录字符的实际颜色
            end
            buffer[y_pos][x_pos] = char unless i > 0 # 中文字符仅在第一个位置写入，避免覆盖
            buffer[y_pos][x_pos+1] = nil if char_w == 2
          end
          char_width += char_w # 更新累计宽度
        end
      end
    end

    def calculate_node_dimensions(available_width, available_height)
      # 只在未设置宽度时计算宽度
      @width ||= if @size
                  [@size, available_width].min
                else
                  available_width
                end

      # 只在未设置高度时计算高度
      @height ||= if @size
                  [@size, available_height].min
                else
                  available_height
                end

      if @content.class == RubyRich::Panel
        @content.width = @width
        @content.height = @height
      end

      return if @children.empty?

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
  end
end