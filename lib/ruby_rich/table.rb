require 'unicode/display_width'

module RubyRich
  class Table
    attr_accessor :headers, :rows, :align, :row_height
  
    def initialize(headers: [], align: :left, row_height: 1)
      @headers = headers.map { |h| format_cell(h) }
      @rows = []
      @align = align
      @row_height = row_height
    end
  
    def add_row(row)
      @rows << row.map { |cell| format_cell(cell) }
    end
  
    def render
      column_widths = calculate_column_widths
      lines = []
  
      # Render headers
      lines << render_row(@headers, column_widths, bold: true)
      lines << "-" * (column_widths.sum { |w| w + 3 } + 1)
  
      # Render rows
      @rows.each do |row|
        lines.concat(render_multiline_row(row, column_widths))
      end
  
      lines.join("\n")
    end
  
    private
  
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