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