module RubyRich
  class Columns
    class Column
      attr_accessor :content, :width, :align, :padding, :title

      def initialize(width: nil, align: :left, padding: 1, title: nil)
        @content = []
        @width = width
        @align = align
        @padding = padding
        @title = title
      end

      def add(text)
        @content << text.to_s
        self
      end

      def <<(text)
        add(text)
      end

      def clear
        @content.clear
        self
      end

      def lines
        @content
      end

      def height
        @content.length
      end
    end

    attr_reader :columns, :total_width, :gutter_width

    def initialize(total_width: 80, gutter_width: 2)
      @columns = []
      @total_width = total_width
      @gutter_width = gutter_width
    end

    # 添加列
    def add_column(width: nil, align: :left, padding: 1, title: nil)
      column = Column.new(width: width, align: align, padding: padding, title: title)
      @columns << column
      
      # 如果没有指定宽度，自动计算平均宽度
      calculate_column_widths if width.nil?
      
      column
    end

    # 删除列
    def remove_column(index)
      @columns.delete_at(index) if index >= 0 && index < @columns.length
      calculate_column_widths
    end

    # 清空所有列的内容
    def clear_all
      @columns.each(&:clear)
      self
    end

    # 渲染列布局
    def render(show_headers: true, show_borders: false, equal_height: true)
      return "" if @columns.empty?

      calculate_column_widths
      lines = []

      # 渲染标题行
      if show_headers && @columns.any? { |col| col.title }
        header_line = render_header_line(show_borders)
        lines << header_line unless header_line.empty?
        
        if show_borders
          separator_line = render_separator_line
          lines << separator_line
        end
      end

      # 准备内容行
      max_height = equal_height ? @columns.map(&:height).max : 0
      
      # 填充较短的列以达到相同高度
      if equal_height && max_height > 0
        @columns.each do |column|
          while column.height < max_height
            column.add("")
          end
        end
      end

      # 渲染内容行
      content_height = @columns.map(&:height).max || 0
      content_height.times do |row_index|
        line = render_content_line(row_index, show_borders)
        lines << line
      end

      # 渲染底部边框
      if show_borders
        bottom_line = render_separator_line
        lines << bottom_line
      end

      lines.join("\n")
    end

    # 按比例设置列宽
    def set_ratios(*ratios)
      return if ratios.length != @columns.length

      total_ratio = ratios.sum.to_f
      available_width = @total_width - (@gutter_width * (@columns.length - 1))
      
      @columns.each_with_index do |column, index|
        column.width = (available_width * ratios[index] / total_ratio).to_i
      end
      
      self
    end

    # 设置等宽列
    def equal_widths
      calculate_column_widths
      self
    end

    private

    def calculate_column_widths
      return if @columns.empty?

      # 计算可用宽度（总宽度减去间隔）
      available_width = @total_width - (@gutter_width * (@columns.length - 1))
      
      # 为每列分配相等的宽度
      base_width = available_width / @columns.length
      remainder = available_width % @columns.length
      
      @columns.each_with_index do |column, index|
        column.width = base_width + (index < remainder ? 1 : 0)
      end
    end

    def render_header_line(show_borders)
      line_parts = []
      
      @columns.each_with_index do |column, index|
        header_text = column.title || ""
        
        # 根据列的对齐方式格式化标题
        formatted_header = format_text(header_text, column.width, column.align)
        
        if show_borders
          formatted_header = "│ #{formatted_header} │"
        end
        
        line_parts << formatted_header
        
        # 添加间隔（除了最后一列）
        if index < @columns.length - 1 && !show_borders
          line_parts << " " * @gutter_width
        end
      end
      
      line_parts.join("")
    end

    def render_content_line(row_index, show_borders)
      line_parts = []
      
      @columns.each_with_index do |column, index|
        content_text = column.lines[row_index] || ""
        
        # 根据列的对齐方式格式化内容
        formatted_content = format_text(content_text, column.width, column.align)
        
        if show_borders
          formatted_content = "│ #{formatted_content} │"
        end
        
        line_parts << formatted_content
        
        # 添加间隔（除了最后一列）
        if index < @columns.length - 1 && !show_borders
          line_parts << " " * @gutter_width
        end
      end
      
      line_parts.join("")
    end

    def render_separator_line
      line_parts = []
      
      @columns.each_with_index do |column, index|
        separator = "─" * (column.width + 2)  # +2 for padding
        line_parts << "├#{separator}┤"
        
        if index < @columns.length - 1
          line_parts << "┬"
        end
      end
      
      line_parts.join("")
    end

    def format_text(text, width, align)
      # 移除 ANSI 转义序列计算实际显示宽度
      display_text = text.gsub(/\e\[[0-9;]*m/, '')
      
      if display_text.length > width
        # 截断过长的文本
        truncated = display_text[0, width - 3] + "..."
        # 保持原有的 ANSI 样式
        if text.include?("\e[")
          style_start = text.match(/\e\[[0-9;]*m/)&.to_s || ""
          truncated = style_start + truncated + "\e[0m"
        end
        truncated
      else
        # 根据对齐方式填充空格
        padding_needed = width - display_text.length
        
        case align
        when :center
          left_padding = padding_needed / 2
          right_padding = padding_needed - left_padding
          " " * left_padding + text + " " * right_padding
        when :right
          " " * padding_needed + text
        else # :left
          text + " " * padding_needed
        end
      end
    end
  end
end