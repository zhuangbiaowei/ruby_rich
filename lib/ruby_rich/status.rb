module RubyRich
  class Status
    # 状态指示器类型
    INDICATORS = {
      # 简单状态
      success: { symbol: '✅', color: "\e[92m", text: 'Success' },
      error: { symbol: '❌', color: "\e[91m", text: 'Error' },
      warning: { symbol: '⚠️', color: "\e[93m", text: 'Warning' },
      info: { symbol: 'ℹ️', color: "\e[94m", text: 'Info' },
      
      # 进度状态
      pending: { symbol: '⏳', color: "\e[93m", text: 'Pending' },
      running: { symbol: '🏃', color: "\e[94m", text: 'Running' },
      completed: { symbol: '✅', color: "\e[92m", text: 'Completed' },
      failed: { symbol: '💥', color: "\e[91m", text: 'Failed' },
      
      # 系统状态
      online: { symbol: '🟢', color: "\e[92m", text: 'Online' },
      offline: { symbol: '🔴', color: "\e[91m", text: 'Offline' },
      maintenance: { symbol: '🔧', color: "\e[93m", text: 'Maintenance' },
      
      # 安全状态
      secure: { symbol: '🔒', color: "\e[92m", text: 'Secure' },
      insecure: { symbol: '🔓', color: "\e[91m", text: 'Insecure' },
      
      # 等级状态
      low: { symbol: '🔵', color: "\e[94m", text: 'Low' },
      medium: { symbol: '🟡', color: "\e[93m", text: 'Medium' },
      high: { symbol: '🔴', color: "\e[91m", text: 'High' },
      critical: { symbol: '💀', color: "\e[95m", text: 'Critical' }
    }.freeze

    # 加载动画帧
    SPINNER_FRAMES = {
      dots: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'],
      line: ['|', '/', '-', '\\'],
      arrow: ['←', '↖', '↑', '↗', '→', '↘', '↓', '↙'],
      bounce: ['⠁', '⠂', '⠄', '⠂'],
      pulse: ['●', '◐', '◑', '◒', '◓', '◔', '◕', '○'],
      clock: ['🕐', '🕑', '🕒', '🕓', '🕔', '🕕', '🕖', '🕗', '🕘', '🕙', '🕚', '🕛']
    }.freeze

    def self.indicator(type, text: nil, show_text: true, colorize: true)
      config = INDICATORS[type.to_sym]
      return "Unknown status: #{type}" unless config
      
      symbol = config[:symbol]
      color = colorize ? config[:color] : ""
      reset = colorize ? "\e[0m" : ""
      status_text = text || config[:text]
      
      if show_text
        "#{color}#{symbol} #{status_text}#{reset}"
      else
        "#{color}#{symbol}#{reset}"
      end
    end

    def self.spinner(type: :dots, text: 'Loading...', delay: 0.1)
      frames = SPINNER_FRAMES[type.to_sym] || SPINNER_FRAMES[:dots]
      
      Thread.new do
        frame_index = 0
        loop do
          print "\r\e[K\e[94m#{frames[frame_index]}\e[0m #{text}"
          $stdout.flush
          sleep delay
          frame_index = (frame_index + 1) % frames.length
        end
      end
    end

    def self.stop_spinner(final_message: nil)
      if final_message
        print "\r\e[K#{final_message}\n"
      else
        print "\r\e[K"
      end
      $stdout.flush
    end

    # 静态进度条
    def self.progress_bar(current, total, width: 30, style: :filled)
      percentage = (current.to_f / total * 100).round(1)
      filled_width = (current.to_f / total * width).round
      
      case style
      when :filled
        filled = '█' * filled_width
        empty = '░' * (width - filled_width)
        bar = "#{filled}#{empty}"
      when :blocks
        filled = '■' * filled_width
        empty = '□' * (width - filled_width)
        bar = "#{filled}#{empty}"
      when :dots
        filled = '●' * filled_width
        empty = '○' * (width - filled_width)
        bar = "#{filled}#{empty}"
      else
        filled = '=' * filled_width
        empty = '-' * (width - filled_width)
        bar = "#{filled}#{empty}"
      end
      
      "\e[92m[#{bar}]\e[0m #{percentage}% (#{current}/#{total})"
    end

    # 状态板
    class StatusBoard
      def initialize(width: 60)
        @width = width
        @items = []
      end

      def add_item(label, status, description: nil)
        @items << {
          label: label,
          status: status,
          description: description
        }
        self
      end

      def render(show_descriptions: true, align_status: :right)
        lines = []
        lines << "┌#{'─' * (@width - 2)}┐"
        
        @items.each do |item|
          label = item[:label]
          status_text = RubyRich::Status.indicator(item[:status])
          description = item[:description]
          
          # 计算实际显示宽度（排除 ANSI 代码）
          status_display_width = status_text.gsub(/\e\[[0-9;]*m/, '').length
          
          case align_status
          when :right
            padding = @width - 4 - label.length - status_display_width
            padding = [padding, 1].max
            main_line = "│ #{label}#{' ' * padding}#{status_text} │"
          when :left
            padding = @width - 4 - label.length - status_display_width
            padding = [padding, 1].max
            main_line = "│ #{status_text} #{label}#{' ' * padding}│"
          else # center
            total_content = label.length + status_display_width + 1
            left_padding = [(@width - 2 - total_content) / 2, 1].max
            right_padding = @width - 2 - total_content - left_padding
            main_line = "│#{' ' * left_padding}#{label} #{status_text}#{' ' * right_padding}│"
          end
          
          lines << main_line
          
          if show_descriptions && description
            desc_lines = wrap_text(description, @width - 4)
            desc_lines.each do |desc_line|
              padding = @width - 4 - desc_line.length
              lines << "│  \e[90m#{desc_line}#{' ' * padding}\e[0m  │"
            end
          end
        end
        
        lines << "└#{'─' * (@width - 2)}┘"
        lines.join("\n")
      end

      private

      def wrap_text(text, max_width)
        words = text.split(' ')
        lines = []
        current_line = ''
        
        words.each do |word|
          if (current_line + ' ' + word).length <= max_width
            current_line += current_line.empty? ? word : ' ' + word
          else
            lines << current_line unless current_line.empty?
            current_line = word
          end
        end
        
        lines << current_line unless current_line.empty?
        lines
      end
    end

    # 实时状态监控
    class Monitor
      def initialize(refresh_rate: 1.0)
        @refresh_rate = refresh_rate
        @items = {}
        @running = false
      end

      def add_item(key, label, &block)
        @items[key] = {
          label: label,
          block: block
        }
        self
      end

      def start
        @running = true
        
        Thread.new do
          while @running
            system('clear')
            puts render_status
            sleep @refresh_rate
          end
        end
      end

      def stop
        @running = false
      end

      private

      def render_status
        lines = []
        lines << "\e[1m\e[96mSystem Status Monitor\e[0m"
        lines << "─" * 40
        lines << ""
        
        @items.each do |key, item|
          begin
            status = item[:block].call
            status_indicator = RubyRich::Status.indicator(status)
            lines << "#{item[:label]}: #{status_indicator}"
          rescue => e
            error_indicator = RubyRich::Status.indicator(:error, text: "Error: #{e.message}")
            lines << "#{item[:label]}: #{error_indicator}"
          end
        end
        
        lines << ""
        lines << "\e[90mPress Ctrl+C to stop monitoring\e[0m"
        lines.join("\n")
      end
    end
  end
end