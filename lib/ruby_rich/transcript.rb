# frozen_string_literal: true

module RubyRich
  class Transcript
    attr_accessor :width, :height
    attr_reader :blocks

    def initialize
      @blocks = []
      @width = 0
      @height = 0
      @selected_collapsible_index = nil
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

    def attach(layout, priority: 150)
      [:ctrl_o, :alt_v].each do |event_name|
        layout.key(event_name, priority) do |event_data, _live|
          handle_event(event_data)
          false
        end
      end

      self
    end

    def handle_event(event_data)
      return false unless @focused

      case event_data[:name]
      when :ctrl_o
        toggle_next(:thinking)
      when :alt_v
        toggle_next(:tool_call)
      end
    end

    def add_user(text)
      add_block(:user, text)
    end

    def add_assistant(text)
      add_block(:assistant, text)
    end

    def add_thinking(text, status: "idle", collapsed: true)
      add_block(:thinking, text, status: status, collapsed: collapsed)
    end

    def add_tool(name, status: :running, result: nil, collapsed: false)
      add_block(:tool_call, result.to_s, name: name, status: status, collapsed: collapsed)
    end

    def add_separator(label = nil)
      add_block(:separator, label.to_s)
    end

    def add_markdown(text)
      add_block(:markdown, text)
    end

    def add_block(type, text = "", **options)
      @blocks << { type: type, text: text.to_s }.merge(options)
      self
    end

    def render
      lines = []
      @blocks.each_with_index do |block, index|
        rendered = render_block(block, index)
        lines.concat(rendered)
      end
      lines
    end

    private

    def render_block(block, index)
      case block[:type]
      when :user
        ["#{AnsiCode.color(:blue, true)}●#{AnsiCode.reset} #{block[:text]}"]
      when :assistant
        ["  #{block[:text]}"]
      when :thinking
        render_thinking(block, index)
      when :tool_call
        render_tool_call(block, index)
      when :separator
        [separator_line(block[:text])]
      when :markdown
        block[:text].split("\n")
      else
        [block[:text]]
      end
    end

    def render_thinking(block, index)
      status = block[:status] || "idle"
      header = "#{AnsiCode.color(:white, true)}... thinking #{status}#{AnsiCode.reset}"
      return [header, "#{AnsiCode.italic}thinking collapsed; press Ctrl+O for full text#{AnsiCode.reset}"] if block[:collapsed]

      [header] + wrap_with_prefix(block[:text], "#{AnsiCode.color(:black, true)}│#{AnsiCode.reset} ")
    end

    def render_tool_call(block, index)
      status = block[:status] || :running
      name = block[:name] || "tool"
      color = status == :failed || status == :issue ? :red : :blue
      header = "#{AnsiCode.color(color, true)}• ▸ #{name} #{status}#{AnsiCode.reset}"
      return [header, "  details collapsed; press Alt+V for details"] if block[:collapsed]

      details = block[:text].empty? ? ["  <no output>"] : wrap_with_prefix(block[:text], "  ")
      [header] + details
    end

    def wrap_with_prefix(text, prefix)
      text.split("\n").flat_map do |line|
        wrap_line(line, [@width - prefix.display_width, 20].max).map { |part| prefix + part }
      end
    end

    def wrap_line(text, max_width)
      return [""] if text.empty?

      result = []
      current = +""
      current_width = 0
      text.each_char do |char|
        char_width = Unicode::DisplayWidth.of(char)
        if current_width + char_width > max_width
          result << current
          current = +""
          current_width = 0
        end
        current << char
        current_width += char_width
      end
      result << current unless current.empty?
      result
    end

    def separator_line(label)
      width = [@width, 20].max
      return "─" * width if label.empty?

      " #{label} ".center(width, "─")
    end

    def toggle_next(type)
      candidates = @blocks.each_index.select { |index| @blocks[index][:type] == type }
      return if candidates.empty?

      current_position = candidates.index(@selected_collapsible_index)
      next_index = candidates[current_position ? (current_position + 1) % candidates.length : 0]
      @selected_collapsible_index = next_index
      @blocks[next_index][:collapsed] = !@blocks[next_index][:collapsed]
    end
  end
end
