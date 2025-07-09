require 'redcarpet'

module RubyRich
  class Markdown
    # 简化的 Markdown 渲染器，将 Markdown 转换为带 ANSI 颜色的终端输出
    class TerminalRenderer < Redcarpet::Render::Base
      def initialize(options = {})
        @options = {
          width: 80,
          indent: '  '
        }.merge(options)
        super()
        
        # 表格状态
        reset_table_state
      end

      def reset_table_state
        @table_state = {
          in_table: false,
          headers: [],
          current_row: [],
          rows: []
        }
      end

      # 段落
      def paragraph(text)
        wrap_text(text) + "\n\n"
      end

      # 标题
      def header(text, level)
        case level
        when 1
          "\e[1m\e[96m#{text}\e[0m\n" + "\e[96m#{'=' * text.length}\e[0m\n\n"
        when 2
          "\e[1m\e[94m#{text}\e[0m\n" + "\e[94m#{'-' * text.length}\e[0m\n\n"
        when 3
          "\e[1m\e[93m### #{text}\e[0m\n\n"
        else
          "\e[1m\e[90m#{'#' * level} #{text}\e[0m\n\n"
        end
      end

      # 代码块
      def block_code(code, language)
        # 简单的代码格式，不使用语法高亮避免循环依赖
        "\e[100m\e[37m" + indent_lines(code.strip) + "\e[0m\n\n"
      end

      # 行内代码
      def codespan(code)
        "\e[47m\e[30m #{code} \e[0m"
      end

      # 引用
      def block_quote(quote)
        lines = quote.strip.split("\n")
        quoted_lines = lines.map { |line| "\e[90m│ \e[37m#{line.strip}" }
        quoted_lines.join("\n") + "\e[0m\n\n"
      end

      # 列表项
      def list_item(text, list_type)
        marker = list_type == :ordered ? '1.' : '•'
        "\e[96m#{marker}\e[0m #{text.strip}\n"
      end

      # 无序列表
      def list(contents, list_type)
        contents + "\n"
      end

      # 强调
      def emphasis(text)
        "\e[3m#{text}\e[23m"
      end

      # 加粗
      def double_emphasis(text)
        "\e[1m#{text}\e[22m"
      end

      # 删除线
      def strikethrough(text)
        "\e[9m#{text}\e[29m"
      end

      # 链接
      def link(link, title, content)
        if title && !title.empty?
          "\e[94m\e[4m#{content}\e[24m\e[0m \e[90m(#{link} - #{title})\e[0m"
        else
          "\e[94m\e[4m#{content}\e[24m\e[0m \e[90m(#{link})\e[0m"
        end
      end

      # 图片
      def image(link, title, alt_text)
        if title && !title.empty?
          "\e[95m[Image: #{alt_text}]\e[0m \e[90m(#{link} - #{title})\e[0m"
        else
          "\e[95m[Image: #{alt_text}]\e[0m \e[90m(#{link})\e[0m"
        end
      end

      # 水平线
      def hrule
        "\e[90m" + "─" * @options[:width] + "\e[0m\n\n"
      end

      # 表格渲染 - 智能分割方法
      def table(header, body)
        return "" if header.nil? && body.nil?
        
        begin
          # 尝试智能分割表格内容
          headers = []
          rows = []
          
          if header && !header.strip.empty?
            # 从header中提取列标题
            header_content = header.strip
            # 尝试按常见模式分割（大写字母开头的单词）
            headers = split_table_content_intelligently(header_content)
          end
          
          if body && !body.strip.empty?
            body_lines = body.strip.split("\n").reject(&:empty?)
            body_lines.each do |line|
              row_data = split_table_content_intelligently(line.strip)
              rows << row_data unless row_data.all?(&:empty?)
            end
          end
          
          # 如果成功解析出了数据，使用RubyRich表格
          if !headers.empty? && !rows.empty?
            table = RubyRich::Table.new(
              headers: headers,
              border_style: @options[:table_border_style] || :simple
            )
            
            rows.each do |row|
              # 确保行长度与标题长度一致
              padded_row = row + Array.new([0, headers.length - row.length].max, "")
              table.add_row(padded_row[0...headers.length])
            end
            
            return table.render + "\n\n"
          end
          
        rescue => e
          # 如果出错，继续使用fallback
        end
        
        # Fallback: 简单显示
        result = "\n"
        if header && !header.strip.empty?
          result += "#{header.strip}\n"
          result += "-" * [header.strip.length, 20].min + "\n"
        end
        if body && !body.strip.empty?
          result += body.strip + "\n"
        end
        result + "\n"
      end

      def table_row(content)
        content + "\n"
      end

      def table_cell(content, alignment)
        content
      end

      # 换行
      def linebreak
        "\n"
      end

      private

      def wrap_text(text, width = nil)
        width ||= @options[:width]
        return text if text.length <= width
        
        words = text.split(' ')
        lines = []
        current_line = ''
        
        words.each do |word|
          if (current_line + ' ' + word).length <= width
            current_line += current_line.empty? ? word : ' ' + word
          else
            lines << current_line unless current_line.empty?
            current_line = word
          end
        end
        
        lines << current_line unless current_line.empty?
        lines.join("\n")
      end

      def indent_lines(text)
        text.split("\n").map { |line| @options[:indent] + line }.join("\n")
      end

      def parse_table_content(content)
        lines = content.strip.split("\n").map(&:strip).reject(&:empty?)
        return [] if lines.empty?
        
        rows = []
        lines.each do |line|
          # 跳过分隔符行（如 |------|--------|）
          next if line.match?(/^\|[\s\-\|:]+\|?$/)
          
          # 解析表格行
          if line.start_with?('|') && line.end_with?('|')
            cells = line[1..-2].split('|').map(&:strip)
            rows << cells unless cells.empty?
          elsif line.include?('|')
            cells = line.split('|').map(&:strip)
            rows << cells unless cells.empty?
          end
        end
        
        rows
      end

      def render_table_with_ruby_rich(rows)
        return "" if rows.empty?
        
        # 使用第一行作为表头
        headers = rows.first
        data_rows = rows[1..-1] || []
        
        # 创建RubyRich表格，使用简单边框样式来匹配markdown风格
        table = RubyRich::Table.new(
          headers: headers,
          border_style: @options[:table_border_style] || :simple
        )
        
        # 添加数据行
        data_rows.each do |row|
          # 确保行长度与标题长度一致
          padded_row = row + Array.new([0, headers.length - row.length].max, "")
          table.add_row(padded_row)
        end
        
        table.render + "\n\n"
      rescue => e
        # 如果表格渲染失败，使用简单的文字格式
        fallback_table_render(rows)
      end

      def fallback_table_render(rows)
        return "" if rows.empty?
        
        result = []
        rows.each_with_index do |row, index|
          result << "| " + row.join(" | ") + " |"
          if index == 0 # 在标题下添加分隔线
            result << "|" + ("-" * (row.join(" | ").length + 2)) + "|"
          end
        end
        
        result.join("\n") + "\n\n"
      end

      def split_table_content_intelligently(content)
        return [] if content.nil? || content.strip.empty?
        
        # 策略1：更智能的分割 - 先尝试找到数字字母边界
        split_points = []
        content.each_char.with_index do |char, index|
          if index > 0 && index < content.length - 1
            prev_char = content[index - 1]
            # 在字母后跟数字，或数字后跟字母的地方分割
            if (prev_char =~ /[A-Za-z]/ && char =~ /\d/) ||
               (prev_char =~ /\d/ && char =~ /[A-Za-z]/)
              split_points << index
            end
          end
        end
        
        if split_points.any?
          parts = []
          last_pos = 0
          split_points.each do |pos|
            parts << content[last_pos...pos] if pos > last_pos
            last_pos = pos
          end
          parts << content[last_pos..-1] if last_pos < content.length
          result = parts.reject(&:empty?)
          return result if result.length >= 2
        end
        
        # 策略2：如果没有数字字母边界，按大写字母分割（但要小心短词）
        words = content.scan(/[A-Z][a-z]+|[A-Z]{2,}/)
        if words.length >= 2 && words.all? { |w| w.length >= 2 }
          return words
        end
        
        # 策略3：按连续的字母和数字分组
        parts = content.scan(/[A-Za-z]+|\d+/)
        if parts.length >= 2
          return parts
        end
        
        # 策略4：按空格分割
        space_parts = content.split(/\s+/).reject(&:empty?)
        if space_parts.length >= 2
          return space_parts
        end
        
        # 最后的fallback：返回原始内容
        [content]
      end
    end

    def self.render(markdown_text, options = {})
      renderer = TerminalRenderer.new(options)
      markdown_processor = Redcarpet::Markdown.new(renderer, {
        fenced_code_blocks: true,
        tables: true,
        autolink: true,
        strikethrough: true,
        space_after_headers: true
      })
      
      markdown_processor.render(markdown_text)
    end

    def initialize(options = {})
      @options = options
    end

    def render(markdown_text)
      self.class.render(markdown_text, @options)
    end
  end
end