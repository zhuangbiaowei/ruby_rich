module RubyRich
  class RichPrint
    def initialize
      @style_regex = /\[([\w\s]+)\](.*?)\[\/[\w]*\]/
    end

    def print(*args)
      processed_args = args.map do |arg|
        next arg unless arg.is_a?(String)
        
        # 处理表情符号
        text = if arg.start_with?(':') && arg.end_with?(':')
          Emoji.find_by_alias(arg[1..-2])&.raw || arg
        else
          arg
        end
        
        # 处理样式标记
        while text.match?(@style_regex)
          text = text.gsub(@style_regex) do |_|
            style, content = $1, $2
            apply_style(content, style)
          end
        end
        
        text
      end
      
      puts processed_args.join(' ')
    end

    private

    def apply_style(content, style)
      style_methods = style.downcase.split
      rich_text = RubyRich::RichText.new(content)
      style.downcase.split.each do |method|
      case method
        when 'bold'
          rich_text.style(bold: true)
        when 'italic'
          rich_text.style(italic: true)
        when 'underline'
          rich_text.style(underline: true)
        when 'blink'
          rich_text.style(blink: true)
        when 'red', 'blue', 'green', 'yellow', 'magenta', 'cyan', 'white', 'black'
          rich_text.style(color: method.to_sym)
        end
      end
      rich_text.render
    end
  end

  # 创建全局打印方法
  $rich_print = RichPrint.new
  def print(*args)
    $rich_print.print(*args)
  end 
end