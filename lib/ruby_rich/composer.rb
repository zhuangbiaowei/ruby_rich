# frozen_string_literal: true

module RubyRich
  class Composer
    attr_accessor :width, :height
    attr_reader :value, :focused, :history

    DEFAULT_MENU_LIMIT = 8

    def initialize(placeholder: "Type a message or /", commands: [], menu_limit: DEFAULT_MENU_LIMIT, on_submit: nil, on_select: nil)
      @placeholder = placeholder
      @commands = normalize_commands(commands)
      @menu_limit = menu_limit
      @on_submit = on_submit
      @on_select = on_select
      @width = 0
      @height = 0
      @value = +""
      @focused = false
      @menu_open = false
      @selected_index = 0
      @history = []
      @history_index = nil
    end

    def attach(layout, priority: 200)
      [:string, :backspace, :delete, :left, :right, :up, :down, :enter, :escape].each do |event_name|
        layout.key(event_name, priority) do |event_data, live|
          handle_event(event_data, live)
          false
        end
      end

      layout.key(:mouse_down, priority) do |_event_data, _live|
        focus
        true
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

    def handle_event(event_data, live = nil)
      case event_data[:name]
      when :string
        append(event_data[:value].to_s)
      when :backspace
        backspace
      when :up
        menu_open? ? move_selection(-1) : history_previous
      when :down
        menu_open? ? move_selection(1) : history_next
      when :enter
        enter(live)
      when :escape
        menu_open? ? close_menu : blur
      end
    end

    def render
      lines = []
      lines << render_input_line
      if menu_open?
        matches = filtered_commands.first(@menu_limit)
        if matches.empty?
          lines << "#{AnsiCode.color(:yellow)}  No matches#{AnsiCode.reset}"
        else
          matches.each_with_index do |command, index|
            lines << render_command(command, index == @selected_index)
          end
        end
      end

      fit_height(lines)
    end

    private

    def append(text)
      @value << text
      @history_index = nil
      @menu_open = true if text == "/" || @menu_open
      clamp_selection
    end

    def backspace
      @value = @value[0...-1].to_s
      @menu_open = false unless @value.include?("/")
      clamp_selection
    end

    def enter(live)
      if menu_open?
        select_current(live)
        return
      end

      submitted = @value.strip
      return if submitted.empty?

      @history << submitted
      @history_index = nil
      @value = +""
      close_menu
      @on_submit&.call(submitted, live)
    end

    def select_current(live)
      command = filtered_commands[@selected_index]
      return unless command

      @value = replace_query_with(command[:value])
      close_menu
      @on_select&.call(command, live)
    end

    def history_previous
      return if @history.empty?

      @history_index = @history_index ? [@history_index - 1, 0].max : @history.length - 1
      @value = @history[@history_index].dup
    end

    def history_next
      return unless @history_index

      @history_index += 1
      if @history_index >= @history.length
        @history_index = nil
        @value = +""
      else
        @value = @history[@history_index].dup
      end
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

    def filtered_commands
      query = current_query.downcase
      return @commands if query.empty?

      @commands.select do |command|
        command[:label].downcase.include?(query) || command[:value].downcase.include?(query)
      end
    end

    def current_query
      slash_index = @value.rindex("/")
      return "" unless slash_index

      @value[(slash_index + 1)..].to_s
    end

    def replace_query_with(replacement)
      slash_index = @value.rindex("/")
      return @value unless slash_index

      @value[0...slash_index].to_s + replacement
    end

    def clamp_selection
      count = [filtered_commands.size, @menu_limit].min
      @selected_index = 0 if count.zero? || @selected_index >= count
    end

    def render_input_line
      focus_color = focused? ? AnsiCode.color(:blue, true) : AnsiCode.color(:black, true)
      prompt = focused? ? ">" : " "
      text = @value.empty? ? "#{AnsiCode.color(:black, true)}#{@placeholder}#{AnsiCode.reset}" : @value
      cursor = focused? ? "#{AnsiCode.color(:blue, true)}_#{AnsiCode.reset}" : " "
      "#{focus_color}#{prompt}#{AnsiCode.reset} #{text}#{cursor}"
    end

    def render_command(command, selected)
      marker = selected ? ">" : " "
      color = selected ? AnsiCode.inverse : AnsiCode.color(:white)
      description = command[:description].to_s
      suffix = description.empty? ? "" : " #{AnsiCode.color(:black, true)}#{description}#{AnsiCode.reset}"
      " #{color}#{marker} #{command[:label]}#{AnsiCode.reset}#{suffix}"
    end

    def fit_height(lines)
      fitted = lines.first([@height, 1].max)
      return fitted unless @width.positive?

      fitted.map { |line| truncate_display(line, @width) }
    end

    def truncate_display(line, max_width)
      return line if line.display_width <= max_width

      result = +""
      width = 0
      line.each_char do |char|
        char_width = char.display_width
        break if width + char_width > max_width

        result << char
        width += char_width
      end
      result
    end

    def normalize_commands(commands)
      commands.map do |command|
        case command
        when Hash
          {
            label: command.fetch(:label, command.fetch("label", command[:value] || command["value"])).to_s,
            value: command.fetch(:value, command.fetch("value", command[:label] || command["label"])).to_s,
            description: command.fetch(:description, command.fetch("description", "")).to_s
          }
        else
          { label: command.to_s, value: command.to_s, description: "" }
        end
      end
    end
  end
end
