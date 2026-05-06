# frozen_string_literal: true

module RubyRich
  class AppShell
    attr_reader :layout, :transcript, :viewport, :sidebar, :composer, :focus_manager, :theme

    DEFAULT_COMMANDS = [
      { label: "help", value: "/help", description: "Show commands" },
      { label: "plan", value: "/plan", description: "Append a plan note" },
      { label: "thinking", value: "/thinking", description: "Add a thinking block" },
      { label: "tool", value: "/tool", description: "Add a tool call" },
      { label: "quit", value: "/quit", description: "Exit demo" }
    ].freeze

    def initialize(title: "Agent", subtitle: nil, model: "deepseek-v4-pro", theme: Theme.agent_dark, commands: DEFAULT_COMMANDS, on_submit: nil)
      @title = title
      @subtitle = subtitle || "DeepSeek-TUI · #{model}"
      @model = model
      @theme = theme
      @on_submit = on_submit
      @status = "agent · #{model}"

      @transcript = Transcript.new
      @viewport = Viewport.new(@transcript, scrollbar: true, auto_scroll: true)
      @sidebar = Sidebar.new
      @composer = Composer.new(
        placeholder: "编写任务或使用 /。",
        commands: commands,
        on_submit: method(:handle_submit),
        on_select: method(:handle_select)
      )
      @focus_manager = FocusManager.new
      @layout = build_layout
      attach_components
    end

    def add_user(text)
      @transcript.add_user(text)
      @viewport.scroll_to_bottom
      self
    end

    def add_assistant(text)
      @transcript.add_assistant(text)
      @viewport.scroll_to_bottom
      self
    end

    def add_thinking(text, status: "idle", collapsed: true)
      @transcript.add_thinking(text, status: status, collapsed: collapsed)
      @viewport.scroll_to_bottom
      self
    end

    def add_tool(name, status: :running, result: nil, collapsed: false)
      @transcript.add_tool(name, status: status, result: result, collapsed: collapsed)
      @viewport.scroll_to_bottom
      self
    end

    def add_separator(label = nil)
      @transcript.add_separator(label)
      @viewport.scroll_to_bottom
      self
    end

    def add_markdown(text)
      @transcript.add_markdown(text)
      @viewport.scroll_to_bottom
      self
    end

    def update_plan(text)
      @sidebar.update_plan(text)
      self
    end

    def set_tasks(tasks)
      @sidebar.set_tasks(tasks)
      self
    end

    def status=(text)
      @status = text.to_s
    end

    def start(refresh_rate: 24, mouse: true, alt_screen: false)
      Live.start(@layout, refresh_rate: refresh_rate, mouse: mouse, alt_screen: alt_screen, autowrap: false) do |live|
        live.listening = true
      end
    end

    private

    def build_layout
      root = Layout.new(name: :root)
      root.split_column(
        Layout.new(name: :header, size: 1),
        Layout.new(name: :body, ratio: 1),
        Layout.new(name: :composer, size: 6),
        Layout.new(name: :status, size: 1)
      )

      root[:body].split_row(
        Layout.new(name: :transcript, ratio: 1),
        Layout.new(name: :sidebar, size: 56)
      )

      root[:header].content = HeaderView.new(self)
      root[:transcript].content = @viewport
      root[:sidebar].content = @sidebar
      root[:composer].content = FramedView.new(@composer, title: "Composer", theme: @theme) { @composer.focused? }
      root[:status].content = StatusView.new(self)
      root
    end

    def attach_components
      @viewport.attach(@layout[:transcript])
      @transcript.attach(@layout[:transcript])
      @composer.focus.attach(@layout[:composer])

      @focus_manager
        .register(:transcript, @layout[:transcript], FocusTarget.new(@transcript, @viewport))
        .register(:composer, @layout[:composer], @composer)
        .attach(@layout)
      @focus_manager.focus(:composer)

      @layout.key(:ctrl_c, 1_000) { |_event, live| live.stop; false }
    end

    def handle_select(command, _live)
      case command[:value]
      when "/plan"
        @status = "plan command selected"
      when "/thinking"
        @status = "thinking command selected"
      when "/tool"
        @status = "tool command selected"
      end
    end

    def handle_submit(value, live)
      case value.strip
      when "/quit"
        live&.stop
      when "/help"
        add_assistant("Commands: /help, /plan, /thinking, /tool, /quit")
      when "/plan"
        @sidebar.add_task("Plan updated #{Time.now.strftime('%H:%M:%S')}", status: :in_progress)
      when "/thinking"
        add_thinking("Let me inspect the current state and keep the details collapsible.", status: "idle", collapsed: false)
      when "/tool"
        add_tool("read_file", status: :done, result: "name: read_file\nresult: <demo output>", collapsed: false)
      else
        add_user(value)
      end

      @on_submit&.call(value, live, self)
    end

    class FocusTarget
      def initialize(*targets)
        @targets = targets
      end

      def focus
        @targets.each { |target| target.focus if target.respond_to?(:focus) }
      end

      def blur
        @targets.each { |target| target.blur if target.respond_to?(:blur) }
      end
    end

    class HeaderView
      attr_accessor :width, :height

      def initialize(shell)
        @shell = shell
        @width = 0
        @height = 1
      end

      def render
        theme = @shell.theme
        left = "#{theme.style(@shell.instance_variable_get(:@title), :accent)}  #{theme.style(@shell.instance_variable_get(:@subtitle), :muted)}"
        right = "#{theme.style('max', :status)}  #{theme.style('● Live', :body)}  #{theme.style('4%', :status)}"
        [join_edges(left, right, @width)]
      end

      private

      def join_edges(left, right, width)
        space = [width - visible_width(left) - visible_width(right), 1].max
        truncate_display(left + (" " * space) + right, width)
      end

      def visible_width(text)
        text.gsub(/\e\[[0-9;:]*m/, "").display_width
      end

      def truncate_display(text, width)
        return text if visible_width(text) <= width

        result = +""
        used = 0
        in_escape = false
        text.each_char do |char|
          if in_escape
            result << char
            in_escape = false if char == "m"
            next
          elsif char.ord == 27
            result << char
            in_escape = true
            next
          end

          char_width = Unicode::DisplayWidth.of(char)
          break if used + char_width > width

          result << char
          used += char_width
        end
        result
      end
    end

    class StatusView
      attr_accessor :width, :height

      def initialize(shell)
        @shell = shell
        @width = 0
        @height = 1
      end

      def render
        theme = @shell.theme
        focus = @shell.focus_manager.focused_name || :none
        line = "#{theme.style(@shell.instance_variable_get(:@status), :accent)}  #{theme.style('focus: ' + focus.to_s, :muted)}  #{theme.style('Tab focus · Ctrl+C quit · /quit', :dim)}"
        [line]
      end
    end

    class FramedView
      attr_accessor :width, :height

      def initialize(component, title:, theme:, &focused)
        @component = component
        @title = title
        @theme = theme
        @focused = focused
        @width = 0
        @height = 0
      end

      def render
        sync_component_dimensions
        panel = Panel.new(rendered_content, title: @title, border_style: @theme.panel_border(focused: @focused.call), title_align: :left)
        panel.width = @width
        panel.height = @height
        panel.render
      end

      private

      def sync_component_dimensions
        inner_width = [@width - 2, 1].max
        inner_height = [@height - 2, 1].max
        @component.width = inner_width if @component.respond_to?(:width=)
        @component.height = inner_height if @component.respond_to?(:height=)
      end

      def rendered_content
        rendered = @component.render
        rendered.is_a?(Array) ? rendered.join("\n") : rendered.to_s
      end
    end
  end
end
