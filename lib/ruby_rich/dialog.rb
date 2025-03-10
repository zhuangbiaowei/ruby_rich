module RubyRich
  class Dialog
    attr_accessor :title, :content, :buttons, :live
    attr_accessor :width, :height

    def initialize(title: "", content: "", width: 48, height: 8, buttons: [:ok])
      @width = width
      @height = height
      terminal_width = `tput cols`.to_i
      terminal_height = `tput lines`.to_i
      @event_listeners = {}
      @layout = RubyRich::Layout.new(name: :title, width: width, height: height)
      @panel = RubyRich::Panel.new("", title: title, border_style: :white)
      @layout.update_content(@panel)
      @layout.calculate_dimensions(terminal_width, terminal_height)
      @button_str = build_button(buttons)
      @panel.content = "  \n  \n#{content}"+AnsiCode.reset+"\n \n \n" + " "*((@panel.inner_width - @button_str.display_width)/2) + @button_str
    end

    def content=(content)
      @panel.content = "  \n  \n#{content}"+AnsiCode.reset+"\n \n \n" + " "*((@panel.inner_width - @button_str.display_width)/2) + @button_str
    end

    def build_button(buttons)
      str = ""
      buttons.each do |btn|        
        case btn
        when :ok
          str += "    "+AnsiCode.color(:blue) + "OK(enter)"+ AnsiCode.reset
        when :cancel
          str += "    "+AnsiCode.color(:red) + "Cancel(esc)"+ AnsiCode.reset
        end
      end
      str.strip
    end

    def render_to_buffer
      @layout.render_to_buffer
    end

    def key(event_name, priority = 0, &block)
      unless @event_listeners[event_name]
        @event_listeners[event_name] = []
      end
      @event_listeners[event_name] << { priority: priority, block: block }
      @event_listeners[event_name].sort_by! { |l| -l[:priority] } # Higher priority first
    end

    def on(event_name, &block)
      if event_name==:close
        @event_listeners[event_name] = [{block: block}]
      end
    end

    def notify_listeners(event_data)
      event_name = event_data[:name]
      result = nil
      if @event_listeners[event_name]
        @event_listeners[event_name].each do |listener|
          result = listener[:block].call(event_data, @live)
        end
        return result
      end
    end
  end
end