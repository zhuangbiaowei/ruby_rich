require 'redcarpet'

module RubyRich
  class Markdown
    # Converts markdown to ANSI-styled terminal output.
    # Uses Redcarpet for block parsing with custom inline processing.
    class TerminalRenderer < Redcarpet::Render::Base
      INLINE_MARKERS = {
        # triple-backtick must come before double-backtick
        %r{```(.+?)```}m => ->(m) { codespan_compat(Regexp.last_match(1)) },
        %r{``(.+?)``}m   => ->(m) { codespan_compat(Regexp.last_match(1)) },
        %r{`(.+?)`}      => ->(m) { codespan_compat(Regexp.last_match(1)) },
        %r{\*\*\*(.+?)\*\*\*} => ->(m) { "#{AnsiCode.bold}#{AnsiCode.italic}#{Regexp.last_match(1)}#{AnsiCode.reset}" },
        %r{\*\*(.+?)\*\*}     => ->(m) { "#{AnsiCode.bold}#{Regexp.last_match(1)}#{AnsiCode.reset}" },
        %r{(?<!\*)\*([^*]+)\*(?!\*)} => ->(m) { "#{AnsiCode.italic}#{Regexp.last_match(1)}#{AnsiCode.reset}" },
        %r{~~(.+?)~~}     => ->(m) { "#{AnsiCode.strikethrough}#{Regexp.last_match(1)}#{AnsiCode.reset}" },
        %r{\[([^\]]+)\]\(([^)]+)\)} => ->(m) {
          link_text = Regexp.last_match(1)
          url = Regexp.last_match(2)
          "#{AnsiCode.color(:blue, true)}#{AnsiCode.underline}#{link_text}#{AnsiCode.reset} #{AnsiCode.color(:black, true)}(#{url})#{AnsiCode.reset}"
        }
      }.freeze

      def initialize(options = {})
        @options = {
          width: 80,
          indent: '  '
        }.merge(options)
        super()
        reset_table_state
      end

      def reset_table_state
        @table_state = { current_row: [], all_rows: [] }
      end

      # ---- block-level callbacks ----

      def paragraph(text)
        "#{process_inline(text)}\n\n"
      end

      def header(text, level)
        processed = process_inline(text)
        case level
        when 1 then "#{AnsiCode.font(:cyan, font_bright: true, bold: true)}#{processed}#{AnsiCode.reset}\n#{AnsiCode.color(:cyan, true)}#{'=' * visible_width(text)}#{AnsiCode.reset}\n\n"
        when 2 then "#{AnsiCode.font(:blue, font_bright: true, bold: true)}#{processed}#{AnsiCode.reset}\n#{AnsiCode.color(:blue, true)}#{'-' * visible_width(text)}#{AnsiCode.reset}\n\n"
        when 3 then "#{AnsiCode.font(:yellow, font_bright: true, bold: true)}### #{processed}#{AnsiCode.reset}\n\n"
        else        "#{AnsiCode.font(:black, font_bright: true, bold: true)}#{'#' * level} #{processed}#{AnsiCode.reset}\n\n"
        end
      end

      def block_code(code, language)
        lang = language&.strip
        lang = nil if lang && lang.empty?
        highlighted = Syntax.highlight(code.strip, lang)
        bg  = AnsiCode.background(:black, true)
        fg  = AnsiCode.color(:white, true)
        pad = @options[:indent]
        "#{bg}#{fg}#{indent_lines(highlighted)}#{AnsiCode.reset}\n\n"
      end

      def codespan(code)
        "#{AnsiCode.background(:white)}#{AnsiCode.color(:black)} #{code} #{AnsiCode.reset}"
      end

      def block_quote(quote)
        lines = quote.strip.split("\n")
        quoted_lines = lines.map { |line| "#{AnsiCode.color(:black, true)}│ #{AnsiCode.color(:white, true)}#{process_inline(line.strip)}" }
        "#{quoted_lines.join("\n")}#{AnsiCode.reset}\n\n"
      end

      def list_item(text, list_type)
        marker = list_type == :ordered ? '1.' : '•'
        "#{AnsiCode.color(:cyan, true)}#{marker}#{AnsiCode.reset} #{process_inline(text.strip)}\n"
      end

      def list(contents, list_type)
        "#{contents}\n"
      end

      def emphasis(text)      = "#{AnsiCode.italic}#{text}#{AnsiCode.reset}"
      def double_emphasis(text) = "#{AnsiCode.bold}#{text}#{AnsiCode.reset}"
      def strikethrough(text)   = "#{AnsiCode.strikethrough}#{text}#{AnsiCode.reset}"

      def link(link, title, content)
        title_part = title && !title.empty? ? " - #{title}" : ""
        "#{AnsiCode.color(:blue, true)}#{AnsiCode.underline}#{content}#{AnsiCode.reset} #{AnsiCode.color(:black, true)}(#{link}#{title_part})#{AnsiCode.reset}"
      end

      def image(link, title, alt_text)
        title_part = title && !title.empty? ? " - #{title}" : ""
        "#{AnsiCode.color(:magenta, true)}[Image: #{alt_text}]#{AnsiCode.reset} #{AnsiCode.color(:black, true)}(#{link}#{title_part})#{AnsiCode.reset}"
      end

      def hrule
        "#{AnsiCode.color(:black, true)}#{"─" * @options[:width]}#{AnsiCode.reset}\n\n"
      end

      def linebreak = "\n"

      # ---- table callbacks ----

      def table(header, body)
        all_rows = @table_state[:all_rows]
        reset_table_state
        return "" if all_rows.empty?

        header_line_count = [header.to_s.strip.split("\n").size, 1].max
        header_rows = all_rows[0...header_line_count]
        body_rows = all_rows[header_line_count..] || []

        return "" if header_rows.empty? || body_rows.empty?

        headers = header_rows.last.map { |c| process_inline(c) }
        begin
          tbl = RubyRich::Table.new(headers: headers, border_style: @options[:table_border_style] || :simple)
          body_rows.each do |row|
            processed = row.map { |c| process_inline(c) }
            padded = processed + Array.new([0, headers.length - processed.length].max, "")
            tbl.add_row(padded[0...headers.length])
          end
          return "#{tbl.render}\n\n"
        rescue
          # fallback
        end

        result = "\n"
        result += "#{header.strip}\n"
        result += "#{"-" * [header.strip.length, 20].min}\n"
        result += "#{body.strip}\n" if body && !body.strip.empty?
        "#{result}\n"
      end

      def table_row(content)
        @table_state[:all_rows] << @table_state[:current_row].dup
        @table_state[:current_row] = []
        "#{content}\n"
      end

      def table_cell(content, alignment)
        @table_state[:current_row] << content.strip
        content
      end

      private

      def process_inline(text)
        return text if text.nil? || text.empty?

        result = text.dup
        INLINE_MARKERS.each do |regex, handler|
          result.gsub!(regex, &handler)
        end
        result
      end

      def self.codespan_compat(code)
        "#{AnsiCode.background(:white)}#{AnsiCode.color(:black)} #{code} #{AnsiCode.reset}"
      end

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
        text.split("\n").map { |line| "#{@options[:indent]}#{line}" }.join("\n")
      end

      def visible_width(text)
        text.gsub(/\e\[[0-9;]*m/, '').length
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
