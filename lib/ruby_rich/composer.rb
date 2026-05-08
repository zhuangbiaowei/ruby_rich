# frozen_string_literal: true

module RubyRich
  class Composer
    attr_accessor :width, :height, :min_height, :max_height
    attr_reader :editor, :focused, :attachments, :history

    DEFAULT_MENU_LIMIT = 8

    def initialize(placeholder: "Type a message or /", commands: [], menu_limit: DEFAULT_MENU_LIMIT,
                   multiline: true, history_path: nil, max_history: 200,
                   on_submit: nil, on_select: nil, on_interrupt: nil, on_eof: nil, on_paste: nil)
      @placeholder = placeholder
      @commands = normalize_commands(commands)
      @menu_limit = menu_limit
      @on_submit = on_submit
      @on_select = on_select
      @on_interrupt = on_interrupt
      @on_eof = on_eof
      @on_paste = on_paste
      @width = 0
      @height = 0
      @min_height = 3
      @max_height = 10
      @editor = LineEditor.new(multiline: multiline, history_path: history_path, max_history: max_history)
      @attachments = []
      @focused = false
      @menu_open = false
      @selected_index = 0
      @ignore_next_tab = false
    end

    def value
      @editor.value
    end

    def history
      @editor.history
    end

    def attach(layout, priority: 200)
      handled_events.each do |event_name|
        layout.key(event_name, priority) do |event_data, live|
          handle_event(event_data, live)
          false
        end
      end

      layout.key(:mouse_down, priority) do |_event_data, _live|
        focus
        false
      end

      self
    end

    def focus
      @focused = true
      self
    end

    def blur
      @focused = false
      close_menu
      self
    end

    def focused?
      @focused
    end

    def menu_open?
      @menu_open
    end

    def wants_tab?
      focused? && (menu_open? || @editor.value.include?("/"))
    end

    def ignore_next_tab
      @ignore_next_tab = true
      self
    end

    def add_attachment(attachment)
      @attachments << normalize_attachment(attachment)
      self
    end

    def register_command(name:, description: "", aliases: [], handler: nil, hidden: false, group: nil)
      command = {
        label: name.to_s,
        value: name.to_s,
        description: description.to_s,
        aliases: aliases.map(&:to_s),
        handler: handler,
        hidden: hidden,
        group: group
      }
      @commands.reject! { |item| item[:value] == command[:value] }
      @commands << command
      self
    end

    def refresh_commands_async(&block)
      Thread.new do
        next_commands = block.call
        @commands = normalize_commands(next_commands) if next_commands
      rescue => e
        RubyRich.logger.error("Command refresh failed: #{e.class}: #{e.message}") if RubyRich.respond_to?(:logger)
      end
    end

    def remove_attachment(index)
      @attachments.delete_at(index.to_i)
    end

    def clear_attachments
      @attachments.clear
      self
    end

    def desired_height
      input_rows = @editor.render_lines(width: inner_width, placeholder: nil, focused: false).length
      attachment_rows = @attachments.empty? ? 0 : [@attachments.length, 3].min
      menu_rows = menu_open? ? [[filtered_commands.length, @menu_limit].min, 1].max : 0
      [[1 + input_rows + attachment_rows + menu_rows, @min_height].max, @max_height].min
    end

    def handle_event(event_data, live = nil)
      return false unless focused?

      case event_data[:name]
      when :string
        insert_text(event_data[:value].to_s)
      when :paste
        handle_paste(event_data[:value].to_s)
      when :left
        @editor.move_left
      when :right
        @editor.move_right
      when :home, :ctrl_a
        @editor.home
      when :end, :ctrl_e
        @editor.end
      when :up
        menu_open? ? move_selection(-1) : @editor.move_up
      when :down
        menu_open? ? move_selection(1) : @editor.move_down
      when :backspace
        @editor.backspace
        sync_menu
      when :delete
        @editor.delete
      when :ctrl_k
        @editor.kill_to_end
      when :ctrl_u
        @editor.kill_to_start
      when :ctrl_w
        @editor.kill_word_back
      when :enter
        enter(live)
      when :shift_enter, :alt_enter, :ctrl_enter
        @editor.newline
      when :escape
        escape
      when :ctrl_c
        invoke_callback(@on_interrupt, live, self)
      when :ctrl_d
        ctrl_d(live)
      when :ctrl_v
        invoke_callback(@on_paste, live, self)
      when :tab
        if @ignore_next_tab
          @ignore_next_tab = false
        else
          menu_open? ? move_selection(1) : open_menu_if_available
        end
      when :shift_tab
        menu_open? ? move_selection(-1) : open_menu_if_available
      end
    end

    def render
      lines = []
      lines.concat(render_attachments)
      lines.concat(render_input_lines)
      lines.concat(render_menu_lines) if menu_open?
      fit_height(lines)
    end

    private

    def handled_events
      [
        :string, :paste,
        :backspace, :delete,
        :left, :right, :up, :down, :home, :end,
        :enter, :shift_enter, :alt_enter, :ctrl_enter, :escape, :tab, :shift_tab,
        :ctrl_a, :ctrl_e, :ctrl_k, :ctrl_u, :ctrl_w, :ctrl_c, :ctrl_d, :ctrl_v
      ]
    end

    def insert_text(text)
      @editor.insert(text)
      @menu_open = true if text.include?("/") || @menu_open
      sync_menu
    end

    def handle_paste(text)
      @editor.insert(text)
      detect_pasted_paths(text).each { |attachment| add_attachment(attachment) }
      invoke_callback(@on_paste, text, self)
      sync_menu
    end

    def enter(live)
      if menu_open? && command_query_is_bare?
        submit_current_selection(live)
        return
      end

      submit_current_value(live)
    end

    def escape
      if menu_open?
        close_menu
      elsif !@editor.empty?
        @editor.clear
      else
        blur
      end
    end

    def ctrl_d(live)
      if @editor.empty?
        if @attachments.empty?
          invoke_callback(@on_eof, live, self)
        else
          remove_attachment(@attachments.length - 1)
        end
      else
        @editor.delete
      end
    end

    def select_current(live)
      command = filtered_commands[@selected_index]
      return unless command

      replace_query_with(command[:value])
      close_menu
      invoke_callback(@on_select, command, live)
    end

    def submit_current_selection(live)
      command = filtered_commands[@selected_index]
      return unless command

      replace_query_with(command[:value])
      close_menu
      invoke_callback(@on_select, command, live)
      submit_current_value(live)
    end

    def submit_current_value(live)
      submitted = @editor.value
      return if submitted.strip.empty? && @attachments.empty?

      attachments = @attachments.dup
      execute_registered_command(submitted, live)
      @editor.submit_value
      clear_attachments
      close_menu
      invoke_callback(@on_submit, submitted, live, attachments)
    end

    def move_selection(delta)
      count = [filtered_commands.size, @menu_limit].min
      return if count.zero?

      @selected_index = (@selected_index + delta) % count
    end

    def close_menu
      @menu_open = false
      @selected_index = 0
    end

    def open_menu_if_available
      @menu_open = true unless filtered_commands.empty?
      clamp_selection
    end

    def sync_menu
      @menu_open = false unless @editor.value.include?("/")
      clamp_selection
    end

    def filtered_commands
      query = current_query.downcase
      commands = @commands.reject { |command| command[:hidden] }
      return commands if query.empty?

      commands.select do |command|
        names = [command[:label], command[:value], *Array(command[:aliases])].map(&:downcase)
        names.any? { |name| name.start_with?("/#{query}") || name.start_with?(query) }
      end
    end

    def visible_commands
      count = [filtered_commands.size, @menu_limit].min
      return [] if count.zero?

      rows = visible_menu_rows
      start = [[@selected_index - rows + 1, 0].max, [count - rows, 0].max].min
      filtered_commands.first(@menu_limit).each_with_index.to_a[start, rows] || []
    end

    def visible_menu_rows
      [[@height - render_attachments.length - 1, 1].max, @menu_limit].min
    end

    def current_query
      before_cursor = @editor.value.chars[0...@editor.cursor].join
      slash_index = before_cursor.rindex("/")
      return "" unless slash_index

      before_cursor[(slash_index + 1)..].to_s
    end

    def command_query_is_bare?
      !current_query.match?(/\s/)
    end

    def replace_query_with(replacement)
      value = @editor.value
      cursor = @editor.cursor
      before = value.chars[0...cursor].join
      after = value.chars[cursor..].join
      slash_index = before.rindex("/")
      return unless slash_index

      @editor.value = before[0...slash_index].to_s + replacement + after
    end

    def clamp_selection
      count = [filtered_commands.size, @menu_limit].min
      @selected_index = 0 if count.zero? || @selected_index >= count
    end

    def render_attachments
      return [] if @attachments.empty?

      @attachments.first(3).each_with_index.map do |attachment, index|
        suffix = attachment.mime_type ? " #{AnsiCode.color(:black, true)}#{attachment.mime_type}#{AnsiCode.reset}" : ""
        "#{AnsiCode.color(:cyan, true)}[#{index + 1}]#{AnsiCode.reset} #{attachment.display_name}#{suffix}"
      end
    end

    def render_input_lines
      focus_color = focused? ? AnsiCode.color(:blue, true) : AnsiCode.color(:black, true)
      prompt = focused? ? ">" : " "
      placeholder = "#{AnsiCode.color(:black, true)}#{@placeholder}#{AnsiCode.reset}"
      input_width = [inner_width - 2, 1].max
      rendered = @editor.render_lines(width: input_width, placeholder: placeholder, focused: focused?)
      rendered.each_with_index.map do |line, index|
        prefix = index.zero? ? "#{focus_color}#{prompt}#{AnsiCode.reset} " : "  "
        prefix + line
      end
    end

    def render_menu_lines
      matches = visible_commands
      return ["#{AnsiCode.color(:yellow)}  No matches#{AnsiCode.reset}"] if matches.empty?

      matches.map { |command, index| render_command(command, index == @selected_index) }
    end

    def render_command(command, selected)
      marker = selected ? ">" : " "
      color = selected ? AnsiCode.inverse : AnsiCode.color(:white)
      description = command[:description].to_s
      suffix = description.empty? ? "" : " #{AnsiCode.color(:black, true)}#{description}#{AnsiCode.reset}"
      " #{color}#{marker} #{command[:label]}#{AnsiCode.reset}#{suffix}"
    end

    def fit_height(lines)
      fitted = lines.last([@height, 1].max)
      return fitted unless @width.positive?

      fitted.map { |line| truncate_display(line, @width) }
    end

    def truncate_display(line, max_width)
      plain_width = line.gsub(/\e\[[0-9;:]*m/, "").display_width
      return line if plain_width <= max_width

      result = +""
      width = 0
      in_escape = false
      escape = +""
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
        break if width + char_width > max_width

        result << char
        width += char_width
      end
      result
    end

    def inner_width
      [@width, 1].max
    end

    def normalize_commands(commands)
      commands.map do |command|
        case command
        when Hash
          {
            label: command.fetch(:label, command.fetch("label", command[:value] || command["value"])).to_s,
            value: command.fetch(:value, command.fetch("value", command[:label] || command["label"])).to_s,
            description: command.fetch(:description, command.fetch("description", "")).to_s,
            aliases: Array(command.fetch(:aliases, command.fetch("aliases", []))).map(&:to_s),
            handler: command[:handler] || command["handler"],
            hidden: command.fetch(:hidden, command.fetch("hidden", false)),
            group: command.fetch(:group, command.fetch("group", nil))
          }
        else
          { label: command.to_s, value: command.to_s, description: "", aliases: [], handler: nil, hidden: false, group: nil }
        end
      end
    end

    def execute_registered_command(text, live)
      stripped = text.strip
      return false unless stripped.start_with?("/")

      name, args = stripped.split(/\s+/, 2)
      command = @commands.find do |item|
        ([item[:value], item[:label]] + Array(item[:aliases])).include?(name)
      end
      return false unless command && command[:handler]

      invoke_callback(command[:handler], args.to_s, live, self)
      true
    end

    def normalize_attachment(attachment)
      return attachment if attachment.is_a?(Attachment)

      Attachment.new(**attachment)
    end

    def invoke_callback(callback, *args)
      return unless callback

      arity = callback.arity
      callback.call(*(arity.negative? ? args : args.first(arity)))
    end

    def detect_pasted_paths(text)
      text.scan(/(?:"([^"]+)"|'([^']+)'|(\S+\.(?:png|jpg|jpeg|gif|webp|txt|md|pdf|json|rb|py|js|ts)))/i).filter_map do |quoted, single, bare|
        path = quoted || single || bare
        next unless path && File.exist?(path)

        Attachment.new(type: attachment_type(path), path: path, mime_type: mime_type(path))
      end
    end

    def attachment_type(path)
      path.match?(/\.(png|jpg|jpeg|gif|webp)\z/i) ? :image : :file
    end

    def mime_type(path)
      case File.extname(path).downcase
      when ".png" then "image/png"
      when ".jpg", ".jpeg" then "image/jpeg"
      when ".gif" then "image/gif"
      when ".webp" then "image/webp"
      when ".md" then "text/markdown"
      when ".txt" then "text/plain"
      when ".json" then "application/json"
      when ".pdf" then "application/pdf"
      else "application/octet-stream"
      end
    end
  end
end
