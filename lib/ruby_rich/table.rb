require 'unicode/display_width'

module RubyRich
  class Table
    attr_accessor :rows, :align, :row_height, :border_style
    attr_reader :headers

    # 边框样式定义
    BORDER_STYLES = {
      none: {
        top: '', bottom: '', left: '', right: '', 
        horizontal: '-', vertical: '|',
        top_left: '', top_right: '', bottom_left: '', bottom_right: '',
        cross: '', top_cross: '', bottom_cross: '', left_cross: '', right_cross: ''
      },
      simple: {
        top: '-', bottom: '-', left: '|', right: '|',
        horizontal: '-', vertical: '|',
        top_left: '+', top_right: '+', bottom_left: '+', bottom_right: '+',
        cross: '+', top_cross: '+', bottom_cross: '+', left_cross: '+', right_cross: '+'
      },
      full: {
        top: '─', bottom: '─', left: '│', right: '│',
        horizontal: '─', vertical: '│',
        top_left: '┌', top_right: '┐', bottom_left: '└', bottom_right: '┘',
        cross: '┼', top_cross: '┬', bottom_cross: '┴', left_cross: '├', right_cross: '┤'
      }
    }.freeze
  
    def initialize(headers: [], align: :left, row_height: 1, border_style: :none)
      @headers = headers.map { |h| format_cell(h) }
      @rows = []
      @align = align
      @row_height = row_height
      @border_style = border_style
    end
  
    def add_row(row)
      @rows << row.map { |cell| format_cell(cell) }
    end

    def headers=(new_headers)
      @headers = new_headers.map { |h| format_cell(h) }
    end
  
    def render
      return render_empty_table if @headers.empty? && @rows.empty?
      
      column_widths = calculate_column_widths
      lines = []
      border_chars = BORDER_STYLES[@border_style] || BORDER_STYLES[:none]

      # Render top border
      if @border_style != :none && !@headers.empty?
        lines << render_horizontal_border(column_widths, :top)
      end

      # Render headers
      unless @headers.empty?
        lines.concat(render_styled_row(@headers, column_widths, bold: true))
        # Header separator line
        lines << render_horizontal_border(column_widths, :middle)
      end

      # Render rows
      @rows.each_with_index do |row, index|
        lines.concat(render_styled_multiline_row(row, column_widths))
      end

      # Render bottom border
      if @border_style != :none && (!@headers.empty? || !@rows.empty?)
        lines << render_horizontal_border(column_widths, :bottom)
      end

      lines.join("\n")
    end
  
    private

    def render_empty_table
      if @border_style == :none
        return "|  |\n-"
      else
        border_chars = BORDER_STYLES[@border_style]
        return "#{border_chars[:top_left]}#{border_chars[:horizontal] * 2}#{border_chars[:top_right]}\n" +
               "#{border_chars[:left]}  #{border_chars[:right]}\n" +
               "#{border_chars[:bottom_left]}#{border_chars[:horizontal] * 2}#{border_chars[:bottom_right]}"
      end
    end

    def render_horizontal_border(column_widths, position)
      return "-" * (column_widths.sum { |w| w + 3 } + 1) if @border_style == :none
      
      border_chars = BORDER_STYLES[@border_style]
      
      # 计算每列的边框宽度（包括左右的空格）
      segments = column_widths.map { |width| border_chars[:horizontal] * (width + 2) }
      
      case position
      when :top
        left_char = border_chars[:top_left]
        right_char = border_chars[:top_right]
        join_char = border_chars[:top_cross]
      when :middle
        left_char = border_chars[:left_cross]
        right_char = border_chars[:right_cross]
        join_char = border_chars[:cross]
      when :bottom
        left_char = border_chars[:bottom_left]
        right_char = border_chars[:bottom_right]
        join_char = border_chars[:bottom_cross]
      else
        left_char = border_chars[:left_cross]
        right_char = border_chars[:right_cross]  
        join_char = border_chars[:cross]
      end
      
      left_char + segments.join(join_char) + right_char
    end

    def render_styled_row(row, column_widths, bold: false)
      if @border_style == :none
        return [render_row(row, column_widths, bold: bold)]
      end
      
      border_chars = BORDER_STYLES[@border_style]
      
      row_content = row.map.with_index do |cell, i|
        content = bold ? cell.render : align_cell(cell.render, column_widths[i])
        aligned_content = align_cell(content, column_widths[i])
        " #{aligned_content} "
      end.join(border_chars[:vertical])
      
      ["#{border_chars[:left]}#{row_content}#{border_chars[:right]}"]
    end

    def render_styled_multiline_row(row, column_widths)
      if @border_style == :none
        return render_multiline_row(row, column_widths)
      end
      
      border_chars = BORDER_STYLES[@border_style]
      
      # Prepare each cell's lines
      row_lines = row.map.with_index do |cell, i|
        # 获取单元格的样式序列
        style_sequence = cell.render.match(/\e\[[0-9;]*m/)&.to_s || ""
        reset_sequence = style_sequence.empty? ? "" : "\e[0m"
        
        # 分割成多行并保持样式
        cell_content = cell.render.split("\n")
        
        # 为每一行添加样式
        cell_content.map! { |line| 
          line = line.gsub(/\e\[[0-9;]*m/, '') # 移除可能存在的样式序列
          style_sequence + line + reset_sequence 
        }
        
        # 填充到指定的行高
        padded_content = cell_content + [" "] * [@row_height - cell_content.size, 0].max
        
        # 对每一行应用对齐，保持样式
        padded_content.map { |line| align_cell(line, column_widths[i]) }
      end

      # Normalize row height
      max_height = row_lines.map(&:size).max
      row_lines.each do |lines|
        width = column_widths[row_lines.index(lines)]
        style_sequence = lines.first.match(/\e\[[0-9;]*m/)&.to_s || ""
        reset_sequence = style_sequence.empty? ? "" : "\e[0m"
        lines.fill(style_sequence + " " * width + reset_sequence, lines.size...max_height)
      end

      # Render each line of the row
      (0...max_height).map do |line_index|
        row_content = row_lines.map { |lines| " #{lines[line_index]} " }.join(border_chars[:vertical])
        "#{border_chars[:left]}#{row_content}#{border_chars[:right]}"
      end
    end
  
    def format_cell(cell)      
      cell.is_a?(RubyRich::RichText) ? cell : RubyRich::RichText.new(cell.to_s)
    end
  
    def calculate_column_widths
      widths = Array.new(@headers.size, 0)
      
      # Calculate widths from headers
      @headers.each_with_index do |header, i|
        header_text = header.respond_to?(:render) ? header.render : header.to_s
        header_width = Unicode::DisplayWidth.of(header_text.gsub(/\e\[[0-9;]*m/, ''))
        widths[i] = [widths[i], header_width].max
      end
      
      # Calculate widths from rows
      @rows.each do |row|
        row.each_with_index do |cell, i|
          cell_lines = cell.render.split("\n")
          cell_lines.each do |line|
            # Remove ANSI escape sequences before calculating width
            plain_line = line.gsub(/\e\[[0-9;]*m/, '')
            width = Unicode::DisplayWidth.of(plain_line)
            widths[i] = [widths[i], width].max
          end
        end
      end
      
      widths
    end
  
    def render_row(row, column_widths, bold: false)
      row.map.with_index do |cell, i|
        content = bold ? cell.render : align_cell(cell.render, column_widths[i])
        align_cell(content, column_widths[i])
      end.join(" | ").prepend("| ").concat(" |")
    end
  
    def render_multiline_row(row, column_widths)
      # Prepare each cell's lines
      row_lines = row.map.with_index do |cell, i|
        # 获取单元格的样式序列
        style_sequence = cell.render.match(/\e\[[0-9;]*m/)&.to_s || ""
        reset_sequence = style_sequence.empty? ? "" : "\e[0m"
        
        # 分割成多行并保持样式
        cell_content = cell.render.split("\n")
        
        # 为每一行添加样式
        cell_content.map! { |line| 
          line = line.gsub(/\e\[[0-9;]*m/, '') # 移除可能存在的样式序列
          style_sequence + line + reset_sequence 
        }
        
        # 填充到指定的行高
        padded_content = cell_content + [" "] * [@row_height - cell_content.size, 0].max
        
        # 对每一行应用对齐，保持样式
        padded_content.map { |line| align_cell(line, column_widths[i]) }
      end
  
      # Normalize row height
      max_height = row_lines.map(&:size).max
      row_lines.each do |lines|
        width = column_widths[row_lines.index(lines)]
        style_sequence = lines.first.match(/\e\[[0-9;]*m/)&.to_s || ""
        reset_sequence = style_sequence.empty? ? "" : "\e[0m"
        lines.fill(style_sequence + " " * width + reset_sequence, lines.size...max_height)
      end
  
      # Render each line of the row
      (0...max_height).map do |line_index|
        row_lines.map { |lines| lines[line_index] }.join(" | ").prepend("| ").concat(" |")
      end
    end
  
    def align_cell(content, width)
      style_sequences = content.scan(/\e\[[0-9;]*m/)
      plain_content = content.gsub(/\e\[[0-9;]*m/, '')
      
      # 计算实际显示宽度
      display_width = Unicode::DisplayWidth.of(plain_content)
      padding_needed = width - display_width
      
      padded_content = case @align
        when :center
          left_padding = padding_needed / 2
          right_padding = padding_needed - left_padding
          " " * left_padding + plain_content + " " * right_padding
        when :right
          " " * padding_needed + plain_content
        else
          plain_content + " " * padding_needed
      end
      
      if style_sequences.any?
        style_sequences.first + padded_content + "\e[0m"
      else
        padded_content
      end
    end
  end  
end 