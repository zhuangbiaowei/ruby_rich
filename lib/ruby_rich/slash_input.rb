# frozen_string_literal: true

module RubyRich
  class SlashInput
    attr_reader :value, :selected_index

    DEFAULT_MENU_LIMIT = 8

    def initialize(prompt: "> ", items: [], width: nil, menu_limit: DEFAULT_MENU_LIMIT, on_select: nil, on_submit: nil)
      @prompt = prompt
      @items = normalize_items(items)
      @width = width
      @menu_limit = menu_limit
      @on_select = on_select
      @on_submit = on_submit
      @value = ""
      @selected_index = 0
      @menu_open = false
    end

    def attach(layout, priority: 100)
      [:string, :backspace, :up, :down, :enter, :escape].each do |event_name|
        layout.key(event_name, priority) do |event_data, live|
          handle_key(event_data, live)
          false
        end
      end
      self
    end

    def handle_key(event_data, live = nil)
      case event_data[:name]
      when :string
        append(event_data[:value].to_s)
      when :backspace
        backspace
      when :up
        move_selection(-1)
      when :down
        move_selection(1)
      when :enter
        enter(live)
      when :escape
        close_menu
      end
    end

    def render
      lines = [input_line]
      return fit_lines(lines) unless menu_open?

      matches = filtered_items.first(@menu_limit)
      if matches.empty?
        lines << "#{AnsiCode.color(:yellow)}  No matches#{AnsiCode.reset}"
      else
        matches.each_with_index do |item, index|
          lines << render_item(item, index == @selected_index)
        end
      end

      fit_lines(lines)
    end

    def menu_open?
      @menu_open
    end

    private

    def append(text)
      @value += text
      @menu_open = true if text == "/" || @menu_open
      clamp_selection
    end

    def backspace
      @value = @value[0...-1].to_s
      @menu_open = false unless @value.include?("/")
      clamp_selection
    end

    def enter(live)
      if @menu_open
        select_current(live)
      else
        @on_submit&.call(@value, live)
      end
    end

    def select_current(live)
      item = filtered_items[@selected_index]
      return unless item

      @value = replace_query_with(item[:value])
      @menu_open = false
      @selected_index = 0
      @on_select&.call(item, live)
    end

    def move_selection(delta)
      return unless @menu_open

      count = [filtered_items.size, @menu_limit].min
      return if count.zero?

      @selected_index = (@selected_index + delta) % count
    end

    def close_menu
      @menu_open = false
      @selected_index = 0
    end

    def filtered_items
      query = current_query.downcase
      return @items if query.empty?

      @items.select do |item|
        item[:label].downcase.include?(query) || item[:value].downcase.include?(query)
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
      count = [filtered_items.size, @menu_limit].min
      @selected_index = 0 if count.zero? || @selected_index >= count
    end

    def input_line
      "#{@prompt}#{@value}"
    end

    def render_item(item, selected)
      marker = selected ? ">" : " "
      color = selected ? AnsiCode.inverse : AnsiCode.color(:white)
      description = item[:description].to_s
      suffix = description.empty? ? "" : " #{AnsiCode.color(:black, true)}#{description}#{AnsiCode.reset}"
      " #{color}#{marker} #{item[:label]}#{AnsiCode.reset}#{suffix}"
    end

    def fit_lines(lines)
      return lines unless @width

      lines.map { |line| truncate_display(line, @width) }
    end

    def truncate_display(line, max_width)
      return line if line.display_width <= max_width

      result = ""
      width = 0
      line.each_char do |char|
        char_width = char.display_width
        break if width + char_width > max_width

        result += char
        width += char_width
      end
      result
    end

    def normalize_items(items)
      items.map do |item|
        case item
        when Hash
          {
            label: item.fetch(:label, item.fetch("label", item[:value] || item["value"])).to_s,
            value: item.fetch(:value, item.fetch("value", item[:label] || item["label"])).to_s,
            description: item.fetch(:description, item.fetch("description", "")).to_s
          }
        else
          { label: item.to_s, value: item.to_s, description: "" }
        end
      end
    end
  end
end
