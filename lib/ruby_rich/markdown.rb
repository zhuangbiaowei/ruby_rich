require 'kramdown'

module RubyRich
  class Markdown
    # 将 Markdown 转换为 ANSI 终端输出。
    # 使用 kramdown 的 AST 遍历 + 自定义 Converter 实现。
    #
    # kramdown 比 redcarpet 的优势：
    #   - 纯 Ruby 实现，无需 C 扩展编译
    #   - 原生 GFM 支持（表格、任务列表、删除线）
    #   - 定义列表 (definition lists)
    #   - 脚注 (footnotes)
    #   - 数学公式 (需 math engine)
    #   - 缩写 (abbreviations)
    #   - 活跃维护

    # === Markdown rendering colour theme. ===
    # Each key maps to `[color, bright]` accepted by AnsiCode.
    MarkdownTheme = {
      heading_1:         [:cyan,     true],
      heading_2:         [:blue,     true],
      heading_3:         [:yellow,   true],
      heading_4_6:       [:black,    true],
      heading_underline: [:cyan,     true],  # H1
      heading_underline2:[:blue,     true],  # H2
      text:              [:white,    true],
      strong_text:       [:white,    true],
      code_border:       [:black,    true],
      code_bg:           [:black,    true],
      code_fg:           [:white,    true],
      inline_code_fg:    [:black,    false],
      inline_code_bg:    [:white,    false],
      blockquote_marker: [:black,    true],
      blockquote_text:   [:white,    true],
      blockquote_italic: true,
      list_level_1:      [:cyan,     true],
      list_level_2:      [:magenta,  true],
      list_level_3:      [:yellow,   true],
      ordered_list:      [:cyan,     true],
      task_checked:      [:green,    true],
      task_unchecked:    [:black,    true],
      link_text:         [:blue,     true],
      link_url:          [:black,    true],
      image_label:       [:magenta,  true],
      rule:              [:black,    true],
      footnote:          [:magenta,  true],
      abbreviation:      [:black,    true],
      math:              [:magenta,  true],
      mark_fg:           [:black,    false],
      mark_bg:           [:yellow,   false],
      kbd_fg:            [:black,    false],
      kbd_bg:            [:white,    false],
      table_border:      :simple
    }.freeze

    class TerminalConverter < Kramdown::Converter::Base

      def initialize(root, options)
        super
        @width = options[:width] || 80
        @indent_str = options[:indent] || '  '
        @table_border_style = options[:table_border_style] || :simple
        @theme = (options[:theme] || MarkdownTheme).freeze
        # 用于有序列表编号
        @list_counters = []
        @list_types = []
      end
    
      # Shortcut: AnsiCode.color with theme lookup.
      def tc(key)
        color, bright = @theme[key]
        AnsiCode.color(color, bright)
      end

      def tbg(key)
        color, bright = @theme[key]
        AnsiCode.background(color, bright)
      end

      def tfont(key, **overrides)
        color, bright = @theme[key]
        AnsiCode.font(color, font_bright: bright, **overrides)
      end

      # 主分发方法 — 根据 AST 元素类型路由到对应处理方法
      def convert(el, _indent = 0)
        case el.type
        when :root         then convert_children(el)
        when :blank        then "\n"
        when :text         then el.value
        when :p            then convert_p(el)
        when :header       then convert_header(el)
        when :codeblock    then convert_codeblock(el)
        when :codespan     then convert_codespan(el)
        when :blockquote   then convert_blockquote(el)
        when :ul           then convert_list(el)
        when :ol           then convert_list(el)
        when :li           then convert_li(el)
        when :em           then convert_em(el)
        when :strong       then convert_strong(el)
        when :em_strong    then convert_em_strong(el)
        when :a            then convert_link(el)
        when :img          then convert_image(el)
        when :hr           then convert_hr(el)
        when :br           then "\n"
        when :table        then convert_table(el)
        when :thead        then convert_children(el)
        when :tbody        then convert_children(el)
        when :tr           then convert_table_row(el)
        when :th           then convert_table_cell(el)
        when :td           then convert_table_cell(el)
        when :html_element then convert_html_element(el)
        when :html_entity  then convert_html_entity(el)
        when :smart_quote  then convert_smart_quote(el)
        when :entity       then el.value.to_s
        when :raw          then convert_raw(el)
        when :comment      then ''
        when :footnote     then convert_footnote(el)
        when :dl           then convert_definition_list(el)
        when :dt           then convert_definition_term(el)
        when :dd           then convert_definition_desc(el)
        when :abbreviation then convert_abbreviation(el)
        when :math         then convert_math(el)
        else
          # 未知类型，递归处理子元素
          if el.children && !el.children.empty?
            convert_children(el)
          else
            el.value || el.text || ''
          end
        end
      end

      private

      # ---- 辅助方法 ----

      def convert_children(el)
        return '' unless el.children
        el.children.map { |child| convert(child) }.join
      end

      def inline_content(el)
        return '' unless el.children
        el.children.map { |child| convert(child) }.join
      end

      def visible_width(text)
        text.to_s.gsub(/\e\[[0-9;]*m/, '').display_width
      end

      # ---- 块级元素 ----

      def convert_p(el)
        "#{inline_content(el)}\n\n"
      end

      def convert_header(el)
        level = el.options[:level] || 1
        text = inline_content(el)
        vw = visible_width(text)
        case level
        when 1
          "#{tfont(:heading_1, bold: true)}#{text}#{AnsiCode.reset}\n" \
          "#{tc(:heading_underline)}#{'=' * [vw, 1].max}#{AnsiCode.reset}\n\n"
        when 2
          "#{tfont(:heading_2, bold: true)}#{text}#{AnsiCode.reset}\n" \
          "#{tc(:heading_underline2)}#{'-' * [vw, 1].max}#{AnsiCode.reset}\n\n"
        when 3
          "#{tfont(:heading_3, bold: true)}### #{text}#{AnsiCode.reset}\n\n"
        else
          prefix = '#' * level
          "#{tfont(:heading_4_6, bold: true)}#{prefix} #{text}#{AnsiCode.reset}\n\n"
        end
      end

      def convert_codeblock(el)
        lang = el.options[:lang]&.strip
        lang = nil if lang && lang.empty?
        code = el.value
        # Preserve trailing newlines for correct line count; strip leading/trailing
        # blank lines that would produce empty first/last code rows.
        code_lines = code.split("\n", -1)
        code_lines.shift while code_lines.first&.strip&.empty?
        code_lines.pop   while code_lines.last&.strip&.empty?
        return "#{tc(:code_border)}┌─ #{lang || "text"} ─┐#{AnsiCode.reset}\n#{tc(:code_border)}└──┘#{AnsiCode.reset}\n\n" if code_lines.empty?

        # Mermaid diagram support
        if lang == "mermaid" || lang == "mmd"
          rendered = MermaidRenderer.render(code, @width.to_i)
          return "#{rendered}\n\n"
        end

        total_lines = code_lines.length
        digit_width = [total_lines.to_s.length, 1].max
        label = lang && !lang.empty? ? lang : "text"
        # Left gutter: "│ " (2) + digits (digit_width) + " │ " (3) = 5 + digit_width
        # Right: " │" (2).  Total overhead = 7 + digit_width.
        gutter_width = 5 + digit_width
        code_width = [@width.to_i - gutter_width - 1, 20].max

        border = tc(:code_border)
        rows = []
        code_lines.each_with_index do |raw_line, idx|
          num = format("%#{digit_width}d", idx + 1)
          highlighted = Syntax.highlight(raw_line, lang)
          fit = fit_code_line(highlighted, code_width)
          rows << "#{border}│#{AnsiCode.reset} #{num} #{border}│#{AnsiCode.reset} #{fit}#{border}│#{AnsiCode.reset}"
        end

        top_border = "#{border}┌─ #{label} #{'─' * [@width.to_i - label.display_width - 5, 2].max}┐#{AnsiCode.reset}"
        bottom_border = "#{border}└#{'─' * (@width.to_i - 2)}┘#{AnsiCode.reset}"

        [top_border, rows.join("\n"), bottom_border, "", ""].join("\n")
      end

      # Fit a syntax-highlighted line to a given display width, preserving
      # ANSI escape sequences and truncating with "…" when necessary.
      def fit_code_line(line, max_width)
        return "" if max_width <= 0

        result = +""
        width = 0
        in_escape = false
        escape = +""
        truncated = false

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
          if width + char_width + 1 > max_width
            truncated = true
            break
          end
          result << char
          width += char_width
        end

        result << "…" if truncated
        result << " " * (max_width - width) unless truncated
        result << AnsiCode.reset
        result
      end

      def convert_codespan(el)
        code = el.value
        "#{tbg(:inline_code_bg)}#{tc(:inline_code_fg)} #{code} #{AnsiCode.reset}"
      end

      def convert_blockquote(el)
        content = inline_content(el)
        lines = content.strip.split("\n")
        marker = tc(:blockquote_marker)
        text_c = tc(:blockquote_text)
        quoted = lines.map do |line|
          "#{marker}│ #{text_c}#{strip_ansi_reset(line)}"
        end
        "#{quoted.join("\n")}#{AnsiCode.reset}\n\n"
      end

      # ---- 列表 ----

      def convert_list(el)
        # 保存/恢复计数器，支持嵌套列表
        @list_counters.push(0)
        @list_types.push(el.type)
        result = convert_children(el)
        @list_types.pop
        @list_counters.pop
        "#{result}\n"
      end

      UNORDERED_MARKERS = { 1 => '•', 2 => '◦', 3 => '▸' }.freeze

      def convert_li(el)
        depth = [@list_types.length, 1].max
        list_type = @list_types.last
        indent = "  " * (depth - 1)
        marker = if list_type == :ol
          @list_counters[-1] += 1
          "#{@list_counters[-1]}."
        else
          UNORDERED_MARKERS[depth.clamp(1, 3)] || '▸'
        end
        task = detect_task_marker(el)
        text = inline_content(el).gsub(/\n{2,}/, "\n")
        if task
          "#{indent}#{tc(task ? :task_checked : :task_unchecked)}#{task}#{AnsiCode.reset} #{text.strip}\n"
        else
          "#{indent}#{tc(list_type == :ol ? :ordered_list : :"list_level_#{depth.clamp(1, 3)}")}#{marker}#{AnsiCode.reset} #{text.strip}\n"
        end
      end

      # Detect GitHub Flavored Markdown task list markers.
      # kramdown-parser-gfm represents them as a child HTML input element
      # inside the li's paragraph (p); we extract the checked state for
      # terminal rendering.
      TASK_CHECKED = '☑'.freeze
      TASK_UNCHECKED = '☐'.freeze

      def detect_task_marker(el)
        return nil unless el.children

        para = el.children.find { |c| c.type == :p }
        return nil unless para&.children

        input_idx = para.children.index { |c| c.type == :html_element && c.value.to_s.downcase == 'input' }
        return nil unless input_idx

        raw = para.children[input_idx].attr['checked']
        checked = raw&.to_s&.downcase == 'checked'
        # Remove the hidden input element so text is clean.
        para.children.delete_at(input_idx)
        checked ? TASK_CHECKED : TASK_UNCHECKED
      end

      # ---- 内联样式 ----

      def convert_em(el)
        "#{AnsiCode.italic}#{inline_content(el)}#{AnsiCode.reset}"
      end

      def convert_strong(el)
        "#{AnsiCode.bold}#{inline_content(el)}#{AnsiCode.reset}"
      end

      def convert_em_strong(el)
        "#{AnsiCode.bold}#{AnsiCode.italic}#{inline_content(el)}#{AnsiCode.reset}"
      end

      # ---- 链接与图片 ----

      def convert_link(el)
        url = el.attr['href'] || ''
        title = el.attr['title']
        text = inline_content(el)
        title_part = title && !title.empty? ? " - #{title}" : ""
        "#{tc(:link_text)}#{AnsiCode.underline}#{text}#{AnsiCode.reset} " \
        "#{tc(:link_url)}(#{url}#{title_part})#{AnsiCode.reset}"
      end

      def convert_image(el)
        url = el.attr['src'] || ''
        title = el.attr['title']
        alt = el.attr['alt'] || ''
        title_part = title && !title.empty? ? " - #{title}" : ""
        "#{tc(:image_label)}[Image: #{alt}]#{AnsiCode.reset} " \
        "#{tc(:link_url)}(#{url}#{title_part})#{AnsiCode.reset}"
      end

      # ---- 水平线 ----

      def convert_hr(_el)
        line_char = '─'
        "#{tc(:rule)}#{line_char * @width}#{AnsiCode.reset}\n\n"
      end

      # ---- 表格（kramdown 原生 AST） ----

      def convert_table(el)
        # 收集表头行和表体行
        header_rows = []
        body_rows = []
        el.children.each do |section|
          case section.type
          when :thead
            section.children.each { |tr| header_rows << collect_row_cells(tr) }
          when :tbody
            section.children.each { |tr| body_rows << collect_row_cells(tr) }
          when :tr
            body_rows << collect_row_cells(section)
          end
        end

        return "" if header_rows.empty? || body_rows.empty?

        headers, fitted_body_rows = fit_table_rows(header_rows.last, body_rows)
        begin
          tbl = RubyRich::Table.new(
            headers: headers,
            border_style: @table_border_style || :simple
          )
          fitted_body_rows.each do |row|
            padded = row + Array.new([0, headers.length - row.length].max, "")
            tbl.add_row(padded[0...headers.length])
          end
          "#{tbl.render}\n\n"
        rescue
          # fallback: plain text table
          result = "\n"
          result += header_rows.last.join(" | ")
          result += "\n#{"-" * [result.strip.length, 20].min}\n"
          body_rows.each { |row| result += row.join(" | ") + "\n" }
          return "#{result}\n"
        end
      end

      # Extract cell text from a table row element.
      def collect_row_cells(tr)
        tr.children.select { |c| [:th, :td].include?(c.type) }
          .map { |c| inline_content(c) }
      end

      def convert_table_row(el)
        convert_children(el)
      end

      def convert_table_cell(el)
        inline_content(el)
      end

      # ---- 表格宽度自适应 ----

      # Fit table cell content to terminal width by normalising column counts,
      # calculating natural widths, constraining to available space, and wrapping
      # cell text.
      def fit_table_rows(header_row, body_rows)
        column_count = [header_row.length, *body_rows.map(&:length)].max.to_i
        normalized_header = header_row + Array.new([0, column_count - header_row.length].max, "")
        normalized_body = body_rows.map { |row| row + Array.new([0, column_count - row.length].max, "") }
        natural_widths = table_natural_widths(normalized_header, normalized_body)
        column_widths = constrain_table_widths(natural_widths)

        headers = normalized_header.each_with_index.map { |cell, index| wrap_table_cell(table_cell_text(cell), column_widths[index]) }
        rows = normalized_body.map do |row|
          row.each_with_index.map { |cell, index| wrap_table_cell(table_cell_text(cell), column_widths[index]) }
        end

        [headers, rows]
      end

      # Maximum display width per column.
      def table_natural_widths(header_row, body_rows)
        rows = [header_row] + body_rows
        return [] if rows.empty?

        rows.transpose.map do |cells|
          cells.map { |cell| cell_display_width(table_cell_text(cell)) }.max.to_i
        end
      end

      # Strip ANSI escape sequences from a cell value.
      def table_cell_text(cell)
        cell.to_s.gsub(/\e\[[0-9;:]*m/, "")
      end

      # Shrink column widths proportionally to fit the terminal width.
      def constrain_table_widths(natural_widths)
        return natural_widths if natural_widths.empty?

        border_overhead = (natural_widths.length * 3) + 1
        max_table_width = [[(@width || 80).to_i - 1, 20].max, border_overhead + natural_widths.length].max
        available_content_width = [max_table_width - border_overhead, natural_widths.length].max
        widths = natural_widths.map { |width| [width, 1].max }
        return widths if widths.sum <= available_content_width

        min_width = available_content_width < natural_widths.length * 3 ? 1 : 3
        while widths.sum > available_content_width
          index = widths.each_with_index.select { |width, _| width > min_width }.max_by(&:first)&.last
          break unless index

          widths[index] -= 1
        end
        widths
      end

      # Wrap cell text to fit a given display width, splitting across newlines
      # and wrapping long lines.
      def wrap_table_cell(text, width)
        width = [width.to_i, 1].max
        text.to_s.split("\n", -1).flat_map do |line|
          wrap_table_line(line, width)
        end.join("\n")
      end

      # Wrap a single line of text to the given display width, preserving any
      # ANSI escape sequences (re-emitted on each wrapped segment).
      def wrap_table_line(line, width)
        return [""] if line.empty?

        lines = []
        current = +""
        current_width = 0
        in_escape = false
        escape = +""

        line.each_char do |char|
          if in_escape
            escape << char
            if char == "m"
              current << escape
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
          if current_width.positive? && current_width + char_width > width
            lines << current
            current = +""
            current_width = 0
          end
          current << char
          current_width += char_width
        end

        lines << current unless current.empty?
        lines.empty? ? [""] : lines
      end

      # Display width of text after stripping ANSI escape sequences, taking the
      # maximum across lines (for multi-line cells).
      def cell_display_width(text)
        text.to_s.gsub(/\e\[[0-9;:]*m/, "").split("\n").map(&:display_width).max.to_i
      end

      # ---- HTML 元素处理 ----

      def convert_html_element(el)
        tag = el.value.to_s.downcase
        content = inline_content(el)

        case tag
        when 'del', 's', 'strike'
          "#{AnsiCode.strikethrough}#{content}#{AnsiCode.reset}"
        when 'ins', 'u'
          "#{AnsiCode.underline}#{content}#{AnsiCode.reset}"
        when 'sub'
          content  # 终端无下标，保留文本
        when 'sup'
          content  # 终端无上标，保留文本
        when 'kbd'
          "#{tbg(:kbd_bg)}#{tc(:kbd_fg)} #{content} #{AnsiCode.reset}"
        when 'mark'
          "#{tbg(:mark_bg)}#{tc(:mark_fg)}#{content}#{AnsiCode.reset}"
        when 'details', 'summary'
          content
        when 'br'
          "\n"
        when 'hr'
          convert_hr(nil)
        else
          content
        end
      end

      def convert_html_entity(el)
        # kramdown 已解析 HTML 实体为 UTF-8 字符
        el.value.to_s
      end

      # ---- 智能引号 ----

      def convert_smart_quote(el)
        case el.value
        when :lsquo then "'"
        when :rsquo then "'"
        when :ldquo then '"'
        when :rdquo then '"'
        else el.value.to_s
        end
      end

      # ---- 原始内容 ----

      def convert_raw(el)
        # 原始 HTML，在终端中通常跳过
        el.value.to_s.start_with?('<') ? '' : el.value.to_s
      end

      # ---- 脚注 ----

      def convert_footnote(el)
        # 脚注内容在文档末尾自动收集
        content = inline_content(el)
        name = el.options[:name]
        "#{tc(:footnote)}[^#{name}]#{AnsiCode.reset}"
      end

      # ---- 定义列表（kramdown 独有） ----

      def convert_definition_list(el)
        "#{convert_children(el)}\n"
      end

      def convert_definition_term(el)
        "#{AnsiCode.bold}#{inline_content(el)}#{AnsiCode.reset}\n"
      end

      def convert_definition_desc(el)
        "#{@indent_str}#{inline_content(el)}\n\n"
      end

      # ---- 缩写（kramdown 独有） ----

      def convert_abbreviation(el)
        title = el.attr['title']
        text = inline_content(el)
        if title && !title.empty?
          "#{AnsiCode.underline}#{text}#{AnsiCode.reset}#{tc(:abbreviation)}(#{title})#{AnsiCode.reset}"
        else
          text
        end
      end

      # ---- 数学公式（kramdown 独有，需 math engine） ----

      def convert_math(el)
        mode = el.options[:category] == :block ? 'block' : 'inline'
        formula = el.value.to_s.strip
        rendered = LatexConverter.convert(formula)
        color = tc(:math)
        if mode == 'block'
          "#{color}#{rendered}#{AnsiCode.reset}\n\n"
        else
          "#{color}#{rendered}#{AnsiCode.reset}"
        end
      end

      # ---- LaTeX to Unicode converter ----
      # Translates common LaTeX math commands to Unicode characters
      # for terminal display. Handles Greek letters, big operators,
      # frac, sqrt, super/subscript, cases, and ~150 common symbols.
      module LatexConverter
        # --- big lookup table ------------------------------------
        # Format: "\\command" => "unicode_char"
        SYMBOLS = {
          # Greek lowercase
          'alpha' => 'α', 'beta' => 'β', 'gamma' => 'γ',
          'delta' => 'δ', 'epsilon' => 'ε', 'varepsilon' => 'ɛ',
          'zeta' => 'ζ', 'eta' => 'η', 'theta' => 'θ',
          'vartheta' => 'ϑ', 'iota' => 'ι', 'kappa' => 'κ',
          'lambda' => 'λ', 'mu' => 'μ', 'nu' => 'ν',
          'xi' => 'ξ', 'pi' => 'π', 'varpi' => 'ϖ',
          'rho' => 'ρ', 'varrho' => 'ϱ', 'sigma' => 'σ',
          'varsigma' => 'ς', 'tau' => 'τ', 'upsilon' => 'υ',
          'phi' => 'φ', 'varphi' => 'ϕ', 'chi' => 'χ',
          'psi' => 'ψ', 'omega' => 'ω',
          # Greek uppercase
          'Gamma' => 'Γ', 'Delta' => 'Δ', 'Theta' => 'Θ',
          'Lambda' => 'Λ', 'Xi' => 'Ξ', 'Pi' => 'Π',
          'Sigma' => 'Σ', 'Upsilon' => 'Υ', 'Phi' => 'Φ',
          'Psi' => 'Ψ', 'Omega' => 'Ω',
          # Relations
          'leq' => '≤', 'geq' => '≥', 'neq' => '≠',
          'equiv' => '≡', 'approx' => '≈', 'sim' => '∼',
          'simeq' => '≃', 'propto' => '∝', 'll' => '≪',
          'gg' => '≫', 'doteq' => '≐', 'prec' => '≺',
          'succ' => '≻', 'preceq' => '≼', 'succeq' => '≽',
          'subset' => '⊂', 'supset' => '⊃', 'subseteq' => '⊆',
          'supseteq' => '⊇', 'in' => '∈', 'ni' => '∋',
          'notin' => '∉', 'perp' => '⊥', 'parallel' => '∥',
          # Binary operators
          'times' => '×', 'div' => '÷', 'cdot' => '·',
          'pm' => '±', 'mp' => '∓', 'oplus' => '⊕',
          'ominus' => '⊖', 'otimes' => '⊗', 'oslash' => '⊘',
          'odot' => '⊙', 'circ' => '∘', 'bullet' => '∙',
          'cap' => '∩', 'cup' => '∪', 'setminus' => '∖',
          'land' => '∧', 'lor' => '∨', 'wedge' => '∧',
          'vee' => '∨', 'star' => '⋆',
          # Arrows
          'to' => '→', 'rightarrow' => '→', 'Rightarrow' => '⇒',
          'leftarrow' => '←', 'Leftarrow' => '⇐',
          'leftrightarrow' => '↔', 'Leftrightarrow' => '⇔',
          'mapsto' => '↦', 'longmapsto' => '⟼',
          'uparrow' => '↑', 'downarrow' => '↓',
          'longrightarrow' => '⟶', 'Longrightarrow' => '⟹',
          # Big operators
          'sum' => '∑', 'prod' => '∏', 'coprod' => '∐',
          'int' => '∫', 'iint' => '∬', 'iiint' => '∭',
          'oint' => '∮', 'bigcup' => '⋃', 'bigcap' => '⋂',
          'bigvee' => '⋁', 'bigwedge' => '⋀',
          # Misc symbols
          'infty' => '∞', 'partial' => '∂', 'nabla' => '∇',
          'forall' => '∀', 'exists' => '∃', 'nexists' => '∄',
          'emptyset' => '∅', 'varnothing' => '∅',
          'Re' => 'ℜ', 'Im' => 'ℑ', 'aleph' => 'ℵ',
          'ell' => 'ℓ', 'hbar' => 'ℏ', 'wp' => '℘',
          'angle' => '∠', 'triangle' => '△', 'triangledown' => '▽',
          'square' => '□', 'Box' => '□', 'diamond' => '◇',
          'clubsuit' => '♣', 'diamondsuit' => '♢',
          'heartsuit' => '♡', 'spadesuit' => '♠',
          'ldots' => '…', 'cdots' => '⋯', 'vdots' => '⋮',
          'ddots' => '⋱', 'dots' => '…',
          'cong' => '≅', 'models' => '⊨', 'mid' => '∣',
          'nmid' => '∤', 'therefore' => '∴', 'because' => '∵',
          'neg' => '¬', 'lnot' => '¬', 'top' => '⊤', 'bot' => '⊥',
          'degree' => '°', 'prime' => '′', 'dag' => '†',
          'ddag' => '‡', 'S' => '§', 'P' => '¶',
          'pound' => '£', 'euro' => '€', 'yen' => '¥',
          'copyright' => '©', 'circledR' => '®',
          # Delimiters – strip LaTeX wrapper
          'left' => '', 'right' => '', 'bigl' => '', 'bigr' => '',
          'Bigl' => '', 'Bigr' => '', 'biggl' => '', 'biggr' => '',
          # Arrows special
          'gets' => '←',
          # Text sub/sup scripts
          'text' => '',
        }.freeze

        # Commands whose argument should be preserved verbatim (e.g. \text{abc})
        TEXT_LIKE = %w[text textrm textsf texttt textbf textit].freeze

        SUPERSCRIPTS = {
          '0' => '⁰', '1' => '¹', '2' => '²', '3' => '³', '4' => '⁴',
          '5' => '⁵', '6' => '⁶', '7' => '⁷', '8' => '⁸', '9' => '⁹',
          '+' => '⁺', '-' => '⁻', '=' => '⁼', '(' => '⁽', ')' => '⁾',
          'i' => 'ⁱ', 'n' => 'ⁿ',
        }.freeze

        SUBSCRIPTS = {
          '0' => '₀', '1' => '₁', '2' => '₂', '3' => '₃', '4' => '₄',
          '5' => '₅', '6' => '₆', '7' => '₇', '8' => '₈', '9' => '₉',
          '+' => '₊', '-' => '₋', '=' => '₌', '(' => '₍', ')' => '₎',
          'a' => 'ₐ', 'e' => 'ₑ', 'i' => 'ᵢ', 'j' => 'ⱼ',
          'n' => 'ₙ', 'x' => 'ₓ',
        }.freeze

        def self.convert(formula)
          return formula if formula.nil? || formula.strip.empty?

          result = formula.dup
          result = process_cases(result)
          result = replace_symbols(result)
          result = process_scripts(result)
          result = process_frac(result)
          result = process_sqrt(result)
          result = strip_delim_spacing(result)
          result
        end

        # Find the index of the } that matches the { at `open_pos`.
        # Returns nil when braces are unbalanced.
        def self.find_matching_brace(text, open_pos)
          return nil unless text[open_pos] == '{'
          depth = 1
          i = open_pos + 1
          while i < text.length && depth > 0
            case text[i]
            when '{' then depth += 1
            when '}' then depth -= 1
            when '\\' then i += 1
            end
            i += 1
          end
          depth == 0 ? i - 1 : nil
        end

        # \frac{num}{den} / \dfrac{num}{den} / \tfrac{num}{den}
        # →  (num)/(den)  when num/den include operators, otherwise num/den
        def self.process_frac(text)
          result = +""
          i = 0
          while i < text.length
            cmd_len = nil
            if text[i..].start_with?('\\dfrac') || text[i..].start_with?('\\tfrac')
              cmd_len = 6
            elsif text[i..].start_with?('\\frac')
              cmd_len = 5
            end
            if cmd_len
              j = i + cmd_len
              while j < text.length && text[j] =~ /\s/
                j += 1
              end
              if j < text.length && text[j] == '{'
                num_start = j
                num_end = find_matching_brace(text, num_start)
                if num_end
                  k = num_end + 1
                  while k < text.length && text[k] =~ /\s/
                    k += 1
                  end
                  if k < text.length && text[k] == '{'
                    den_start = k
                    den_end = find_matching_brace(text, den_start)
                    if den_end
                      num = text[num_start + 1...num_end]
                      den = text[den_start + 1...den_end]
                      # Only wrap in parens when the expression includes
                      # operators that would change precedence without them.
                      op_rx = /[+\-±∓×÷=<>]/
                      num_wrap = num =~ op_rx ? "(#{num})" : num
                      den_wrap = den =~ op_rx ? "(#{den})" : den
                      result << "#{num_wrap}/#{den_wrap}"
                      i = den_end + 1
                      next
                    end
                  end
                end
              end
            end
            result << text[i]
            i += 1
          end
          result
        end

        # \sqrt{x} → √(x)   \sqrt[n]{x} → ⁿ√(x)
        def self.process_sqrt(text)
          result = +""
          i = 0
          while i < text.length
            if text[i..].start_with?('\\sqrt')
              j = i + 5
              deg_text = nil
              while j < text.length && text[j] =~ /\s/
                j += 1
              end
              if j < text.length && text[j] == '['
                close_br = text.index(']', j)
                if close_br
                  deg_text = text[j + 1...close_br]
                  j = close_br + 1
                end
              end
              while j < text.length && text[j] =~ /\s/
                j += 1
              end
              if j < text.length && text[j] == '{'
                rad_start = j
                rad_end = find_matching_brace(text, rad_start)
                if rad_end
                  rad = text[rad_start + 1...rad_end]
                  prefix = deg_text ? script_chars(deg_text, SUPERSCRIPTS) : ''
                  result << "#{prefix}√(#{rad})"
                  i = rad_end + 1
                  next
                end
              end
            end
            result << text[i]
            i += 1
          end
          result
        end

        # \begin{cases} ... \end{cases}  →  ⎧ … ⎨ … ⎩ …
        def self.process_cases(text)
          text.gsub(/\\begin\{cases\}(.*?)\\end\{cases\}/m) do
            body = Regexp.last_match(1).strip
            lines = body.split('\\\\').map(&:strip).reject(&:empty?)
            return '{}' if lines.empty?
            out = +""
            lines.each_with_index do |line, i|
              leader = case i
                       when 0 then '⎧'
                       when lines.length - 1 then '⎩'
                       else '⎨'
                       end
              out << "#{leader} #{line.gsub('&', '')}\n"
            end
            out.strip
          end
        end

        # ^{x} / _{x}  →  Unicode super/subscript
        def self.process_scripts(text)
          # ^{...}
          text = text.gsub(/\^\{([^}]+)\}/) {
            inner = Regexp.last_match(1)
            inner.include?('\\') ? "^\{#{inner}\}" : script_chars(inner, SUPERSCRIPTS)
          }
          # _{...}
          text = text.gsub(/_\{([^}]+)\}/) {
            inner = Regexp.last_match(1)
            inner.include?('\\') ? "_\{#{inner}\}" : script_chars(inner, SUBSCRIPTS)
          }
          # ^x  (single non-whitespace char, not \ or {)
          text = text.gsub(/\^([^\s\\{])/) { SUPERSCRIPTS[Regexp.last_match(1)] || "^#{Regexp.last_match(1)}" }
          # _x  (single non-whitespace char, not \ or {)
          text = text.gsub(/_([^\s\\{])/) { SUBSCRIPTS[Regexp.last_match(1)] || "_#{Regexp.last_match(1)}" }
          text
        end

        def self.script_chars(str, map)
          str.each_char.map { |c| map[c] || c }.join
        end

        # Replace \command tokens with Unicode equivalents.
        def self.replace_symbols(text)
          # Handle brace-wrapped font/formatting commands: \text{ab}, \mathbf{ab}, \mathbb{R}, etc.
          # Strip the wrapper, keep the content.
          text = text.gsub(/\\(?:text\w*|math[bif]|mathbf|mathrm|mathit|mathsf|mathtt|mathcal|mathfrak|mathbb|mathscr|boldsymbol|bm|emph)\s*\{(.*?)\}/) {
            Regexp.last_match(1)
          }
          # Handle font commands with single-char arg (space-separated): \mathbf E
          text = text.gsub(/\\(?:mathbf|mathrm|mathit|mathsf|mathtt|mathcal|mathfrak|mathbb|mathscr|boldsymbol|bm)\s+([a-zA-Z0-9])/) {
            Regexp.last_match(1)
          }
          # Replace all other \commands
          text.gsub(/\\([a-zA-Z]+)/) { |m|
            SYMBOLS[Regexp.last_match(1)] || m
          }
        end

        # Remove stray spaces inserted by \left / \right.
        def self.strip_delim_spacing(text)
          text.gsub(/\(\s+/, '(').gsub(/\s+\)/, ')')
              .gsub(/\[\s+/, '[').gsub(/\s+\]/, ']')
              .gsub(/\{\s+/, '{').gsub(/\s+\}/, '}')
              .gsub(/\\s+/, ' ')
              .gsub(/([·×÷]) +/, '\1')
              .gsub(/ +([·×÷])/, '\1')
        end
      end

      # ---- Mermaid diagram renderer ----
      # Renders pie charts inline; other diagram types show source with a
      # hint to install `mmdc` for full rendering.
      module MermaidRenderer
        BAR_MAX = 32

        LEAF_BIN = "leaf"

        def self.leaf_available?
          @leaf_available ||= system("which #{LEAF_BIN} > /dev/null 2>&1")
        end

        def self.render_via_leaf(source, width)
          return nil unless leaf_available?
          IO.popen([LEAF_BIN, "--inline", "plain:#{width}"], "r+", err: "/dev/null") do |io|
            io.write(source)
            io.close_write
            io.read.strip
          end
        rescue
          nil
        end

        def self.render(source, width = 80)
          trimmed = source.strip
          return "" if trimmed.empty?

          type = detect_type(trimmed)
          case type
          when :pie
            render_pie(trimmed, width)
          when :flowchart, :sequence, :class, :gantt, :state, :generic
            # Prefer leaf for high-quality ASCII-art rendering
            result = render_via_leaf("```mermaid\n#{trimmed}\n```\n", width)
            result && !result.empty? ? result : render_fallback(trimmed, type, width)
          else
            render_fallback(trimmed, type, width)
          end
        end

        def self.detect_type(source)
          first = source.lines.first&.strip&.downcase || ""
          return :pie if first.start_with?("pie")
          return :flowchart if first.start_with?("flowchart") || first.start_with?("graph")
          return :sequence  if first.start_with?("sequencediagram")
          return :class     if first.start_with?("classdiagram")
          return :gantt     if first.start_with?("gantt")
          return :state     if first.start_with?("statediagram")
          :generic
        end

        # Pie chart → horizontal bar chart with percentage labels.
        def self.render_pie(source, width)
          title = ""
          entries = []
          source.each_line do |line|
            line = line.strip
            next if line.empty?
            if line.downcase.start_with?("pie")
              rest = line[3..].strip
              if rest.downcase.start_with?("title")
                title = rest[5..].strip
              end
              next
            end
            if line.downcase.start_with?("title")
              title = line[5..].strip
              next
            end
            # Parse "label" : value
            label_part, value_part = line.split(":", 2).map(&:strip)
            next unless label_part && value_part
            label = label_part.delete_prefix('"').delete_suffix('"')
            value = value_part.to_f
            entries << [label, value] if value > 0
          end

          return "[Mermaid pie: no data]" if entries.empty?

          total = entries.sum { |_l, v| v }
          return "[Mermaid pie: total is zero]" if total <= 0

          max_label = entries.map { |l, _| l.length }.max
          out = +""
          out << "#{tc(:heading_3)}#{title}#{AnsiCode.reset}\n" unless title.empty?

          entries.each do |label, value|
            pct = value / total * 100.0
            filled = (pct / 100.0 * BAR_MAX).round
            half = (pct / 100.0 * BAR_MAX * 2).round % 2 == 1
            bar = "█" * filled + (half ? "▌" : "")
            out << sprintf("%-#{BAR_MAX + 1}s %-#{max_label}s %5.1f%%\n", bar, label, pct)
          end

          out.strip
        end

        # Fallback: show diagram source with a labelled header.
        def self.render_fallback(source, type, width)
          label = type.to_s.capitalize
          pad = (width - label.length - 2).clamp(2, 60)
          lines = source.lines.map(&:chomp)
          [
            "#{tc(:code_border)}┌─ #{label} #{'─' * pad}┐#{AnsiCode.reset}",
            *lines.map { |l| "#{tc(:code_border)}│#{AnsiCode.reset} #{l}" },
            "#{tc(:code_border)}└#{'─' * (width - 2)}┘#{AnsiCode.reset}",
            "#{tc(:muted || :heading_4_6)}Install mmdc (npm i -g @mermaid-js/mermaid-cli) for full diagram rendering.#{AnsiCode.reset}",
          ].join("\n")
        end

        # Flowchart / graph → edge-list rendering with node labels.
        def self.render_flowchart(source, width)
          lines = source.lines.map(&:chomp)
          # Build node registry: id => label
          nodes = {}
          edges = []

          lines.each do |line|
            stripped = line.strip
            next if stripped.empty?
            next if stripped.downcase.start_with?("flowchart", "graph")

            # Parse edge:  src ---|label|---> tgt
            m = stripped.match(
              /\A(.+?)\s*(-+>|==+>|-\.+>|=+>)\s*(\|(.*?)\|)?\s*(.+)\z/
            )
            if m
              src_raw = m[1].strip
              tgt_raw = m[5].strip
              arrow = m[2]
              label = m[4]&.strip

              src_id, src_lbl = parse_node(src_raw)
              tgt_id, tgt_lbl = parse_node(tgt_raw)

              # Only store shaped labels — don't let bare IDs overwrite them
              nodes[src_id] = src_lbl if src_lbl && src_raw =~ /[\[\(\{]/
              nodes[tgt_id] = tgt_lbl if tgt_lbl && tgt_raw =~ /[\[\(\{]/

              edges << {
                src: src_id, src_label: src_lbl || src_id,
                tgt: tgt_id, tgt_label: tgt_lbl || tgt_id,
                edge_label: label
              }
              next
            end

            # Standalone node definition:  id[text] / id{text} / id(text)
            nm = stripped.match(/\A([A-Za-z0-9_]+)\s*[\[\(\{].+[\]\)\}]\z/)
            if nm
              nid, nlbl = parse_node(stripped)
              nodes[nid] = nlbl if nlbl
            end
          end

          return "[Mermaid flowchart: no edges found]" if edges.empty?

          out = +""
          edges.each do |e|
            src = nodes[e[:src]] || e[:src_label]
            tgt = nodes[e[:tgt]] || e[:tgt_label]
            lbl = e[:edge_label] ? " ─#{e[:edge_label]}─▶ " : " ──▶ "
            out << "#{src}#{lbl}#{tgt}\n"
          end
          out.strip
        end

        # Extract [id, label] from a node token like "A[开始]" or "B{是否通过?}"
        def self.parse_node(raw)
          raw = raw.strip
          # Square brackets
          if raw =~ /\A([A-Za-z0-9_]+)\s*\[(.+)\]\z/
            [$1, $2]
          # Curly braces (diamond)
          elsif raw =~ /\A([A-Za-z0-9_]+)\s*\{(.+)\}\z/
            [$1, $2]
          # Round parens
          elsif raw =~ /\A([A-Za-z0-9_]+)\s*\((.+)\)\z/
            [$1, $2]
          # Just an id
          elsif raw =~ /\A([A-Za-z0-9_]+)\z/
            [$1, $1]
          else
            [raw, raw]
          end
        end

        # Sequence diagram → participant-message listing.
        def self.render_sequence(source, width)
          lines = source.lines.map(&:chomp)
          participants = []
          messages = []

          lines.each do |line|
            stripped = line.strip
            next if stripped.empty? || stripped.downcase.start_with?("sequencediagram")

            # participant / actor definition
            if stripped =~ /\A(?:participant|actor)\s+(.+)\z/i
              participants << $1.strip
              next
            end

            # Note
            if stripped =~ /\ANote\s+(?:over\s+)?(.+?):\s*(.+)\z/i
              messages << { type: :note, target: $1.strip, text: $2.strip }
              next
            end

            # Message:  A->>B: text  /  A-->>B: text  /  A-)B: text
            if stripped =~ /\A(.+?)\s*(-+>>?|-->>|-\)|-[xX])\s*(.+?)\s*:\s*(.+)\z/
              src  = $1.strip
              arrow_type = $2.strip
              tgt  = $3.strip
              text = $4.strip
              participants |= [src, tgt] unless participants.include?(src) && participants.include?(tgt)
              dashed = arrow_type.start_with?("--")
              messages << { type: :msg, src: src, tgt: tgt, text: text, dashed: dashed }
            end
          end

          return "[Mermaid sequence: no messages found]" if messages.empty?

          max_participant = participants.map(&:length).max
          max_participant = 8 if max_participant < 8

          out = +""
          participants.each do |p|
            out << sprintf("%-#{max_participant + 4}s", "[#{p}]")
          end
          out << "\n#{'─' * ((max_participant + 4) * participants.size)}\n"

          messages.each do |m|
            case m[:type]
            when :note
              out << "  📝 #{m[:target]}: #{m[:text]}\n"
            when :msg
              src_idx = participants.index(m[:src]) || 0
              tgt_idx = participants.index(m[:tgt]) || participants.size - 1
              rightward = src_idx <= tgt_idx
              if m[:dashed]
                arrow = rightward ? "╌╌▶" : "◀╌╌"
              else
                arrow = rightward ? "──▶" : "◀──"
              end
              out << sprintf("  %-#{max_participant}s #{arrow} %s: %s\n",
                             m[:src], m[:tgt], m[:text])
            end
          end
          out.strip
        end

        # Proxy theme colour access (same instance as TerminalConverter).
        def self.tc(key)
          color, bright = MarkdownTheme[key]
          AnsiCode.color(color, bright)
        end

        def self.AnsiCode
          ::RubyRich::AnsiCode
        end
      end

      # ---- 辅助 ----

      def indent_lines(text)
        text.split("\n").map { |line| "#{@indent_str}#{line}" }.join("\n")
      end

      def strip_ansi_reset(text)
        # 去掉末尾 AnsiCode.reset，让 blockquote 统一添加
        text.gsub(/\e\[0m$/, '')
      end
    end

    # ---- Frontmatter extraction ----
    # Extracts YAML-style frontmatter (delimited by ---) and returns
    # [content_without_fm, parsed_pairs, is_vertical].
    module Frontmatter
      VERTICAL_THRESHOLD = 5

      def self.extract(markdown_text)
        # Strip leading blank lines so that a heredoc like <<~'MD'\n\n---\n
        # is still recognised as having frontmatter.
        stripped = markdown_text.lstrip
        return [markdown_text, nil, false] unless stripped.start_with?("---")

        rest = stripped[3..]
        offset = 3
        rest.each_line do |line|
          trimmed = line.strip
          if trimmed == "---" || trimmed == "..."
            fm_block = stripped[3...offset]
            content = stripped[(offset + line.length)..] || ""
            pairs = parse_pairs(fm_block)
            return [markdown_text, nil, false] if pairs.empty?
            vertical = pairs.length >= VERTICAL_THRESHOLD
            return [content, pairs, vertical]
          end
          offset += line.length
        end
        [markdown_text, nil, false]
      end

      def self.parse_pairs(block)
        pairs = []
        lines = block.lines.map(&:chomp)
        i = 0
        while i < lines.length
          trimmed = lines[i].strip
          i += 1 and next if trimmed.empty? || trimmed.start_with?('#')

          colon_pos = trimmed.index(':')
          i += 1 and next unless colon_pos

          key = trimmed[0...colon_pos].strip
          raw_value = trimmed[(colon_pos + 1)..].strip
          i += 1 and next if key.empty?

          if [">-", ">", "|", "|-"].include?(raw_value)
            # Multiline value with explicit indicator
            i += 1
            parts = []
            while i < lines.length && lines[i].start_with?(' ', "\t")
              part = lines[i].strip
              parts << part unless part.empty?
              i += 1
            end
            pairs << [key, parts.join(" ")]
          elsif raw_value.empty?
            # Empty value: could be a list or an implicit multiline string.
            i += 1
            items = []
            while i < lines.length && lines[i].start_with?(' ', "\t")
              item = lines[i].strip
              items << (item.start_with?("- ") ? item[2..].strip : item)
              i += 1
            end
            pairs << [key, items.empty? ? "" : items.join(", ")]
          else
            pairs << [key, unquote(raw_value)]
            i += 1
          end
        end
        pairs
      end

      def self.unquote(s)
        (s.length >= 2 && ((s.start_with?('"') && s.end_with?('"')) || (s.start_with?("'") && s.end_with?("'")))) ? s[1...-1] : s
      end
    end

    # ---- 公开 API ----

    # 渲染 Markdown 文本为 ANSI 终端输出
    #
    # @param markdown_text [String] 输入的 Markdown 文本
    # @param options [Hash] 渲染选项
    # @option options [Integer] :width 终端宽度（默认 80）
    # @option options [String] :indent 缩进字符串（默认 '  '）
    # @option options [Symbol] :table_border_style 表格边框样式 (:none, :simple, :full)
    # @option options [Hash] :kramdown 传递给 Kramdown::Document 的额外选项
    #
    # @return [String] ANSI 格式的终端输出
    def self.render(markdown_text, options = {})
      converter_options = {
        width: options[:width] || 80,
        indent: options[:indent] || '  ',
        table_border_style: options[:table_border_style] || :simple
      }

      # Pre-process frontmatter
      content, fm_pairs, fm_vertical = Frontmatter.extract(markdown_text)

      # Pre-process inline math $...$ (kramdown needs a math-engine gem for this)
      math_color = AnsiCode.color(*MarkdownTheme[:math])
      content = content.gsub(/(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)/) do
        rendered = TerminalConverter::LatexConverter.convert(Regexp.last_match(1).strip)
        "#{math_color}#{rendered}#{AnsiCode.reset}"
      end

      fm_output = ""
      if fm_pairs && !fm_pairs.empty?
        if fm_vertical
          # Vertical frontmatter: one column per key-value pair
          fm_output = render_frontmatter_vertical(fm_pairs, converter_options)
        else
          fm_output = render_frontmatter_horizontal(fm_pairs, converter_options)
        end
      end

      kramdown_opts = {
        input: 'GFM',                 # GitHub Flavored Markdown
        syntax_highlighter: nil,      # 自行处理语法高亮
        hard_wrap: false,
        html_to_native: true,
        line_width: converter_options[:width]
      }.merge(options[:kramdown] || {})

      doc = Kramdown::Document.new(content, kramdown_opts)
      result, _warnings = TerminalConverter.convert(doc.root, converter_options)
      "#{fm_output}#{result}"
    end

    # Render frontmatter as a vertical key-value table (many pairs).
    def self.render_frontmatter_vertical(pairs, opts)
      tbl = RubyRich::Table.new(
        headers: %w[Key Value],
        border_style: opts[:table_border_style] || :simple
      )
      pairs.each { |k, v| tbl.add_row([k, v]) }
      "#{tbl.render}\n\n"
    end

    # Render frontmatter as a horizontal 2-row table (few pairs).
    def self.render_frontmatter_horizontal(pairs, opts)
      keys = pairs.map(&:first)
      vals = pairs.map(&:last)
      tbl = RubyRich::Table.new(
        headers: keys,
        border_style: opts[:table_border_style] || :simple
      )
      tbl.add_row(vals)
      "#{tbl.render}\n\n"
    end

    def initialize(options = {})
      @options = options
    end

    def render(markdown_text)
      self.class.render(markdown_text, @options)
    end
  end
end