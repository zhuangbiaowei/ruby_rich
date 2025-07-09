module RubyRich
  class ProgressBar
    
    attr_reader :progress, :total, :start_time

    # 进度条样式
    STYLES = {
      default: { filled: '=', empty: ' ', prefix: '[', suffix: ']' },
      blocks: { filled: '█', empty: '░', prefix: '[', suffix: ']' },
      arrows: { filled: '>', empty: '-', prefix: '[', suffix: ']' },
      dots: { filled: '●', empty: '○', prefix: '(', suffix: ')' },
      line: { filled: '━', empty: '─', prefix: '│', suffix: '│' },
      gradient: { filled: ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'], empty: ' ', prefix: '[', suffix: ']' }
    }.freeze

    def initialize(total, width: 50, style: :default, title: nil, show_percentage: true, show_rate: false, show_eta: false)
      @total = total
      @progress = 0
      @width = width
      @style = style
      @title = title
      @show_percentage = show_percentage
      @show_rate = show_rate
      @show_eta = show_eta
      @start_time = nil
      @last_update_time = nil
      @update_history = []
    end

    def start
      @start_time = Time.now
      @last_update_time = @start_time
      render
    end

    def advance(amount = 1)
      @start_time ||= Time.now
      @progress += amount
      @progress = [@progress, @total].min
      
      current_time = Time.now
      @update_history << { time: current_time, progress: @progress }
      
      # 保留最近的几个更新用于计算速率
      @update_history = @update_history.last(10)
      @last_update_time = current_time
      
      render
      puts if completed?
    end

    def set_progress(value)
      @start_time ||= Time.now
      @progress = [[value, 0].max, @total].min
      
      current_time = Time.now
      @update_history << { time: current_time, progress: @progress }
      @update_history = @update_history.last(10)
      @last_update_time = current_time
      
      render
      puts if completed?
    end

    def completed?
      @progress >= @total
    end

    def percentage
      return 0 if @total == 0
      (@progress.to_f / @total * 100).round(1)
    end

    def elapsed_time
      return 0 unless @start_time
      Time.now - @start_time
    end

    def rate
      return 0 if @update_history.length < 2
      
      first_update = @update_history.first
      last_update = @update_history.last
      
      time_diff = last_update[:time] - first_update[:time]
      progress_diff = last_update[:progress] - first_update[:progress]
      
      return 0 if time_diff == 0
      progress_diff / time_diff
    end

    def eta
      return 0 if rate == 0 || completed?
      remaining = @total - @progress
      remaining / rate
    end

    def render
      bar_content = render_bar
      status_text = render_status
      
      output = ""
      output << "\e[94m#{@title}: \e[0m" if @title
      output << bar_content
      output << " #{status_text}" unless status_text.empty?
      
      print "\r\e[K#{output}"
      $stdout.flush
    end

    def finish(message: nil)
      if message
        puts "\r\e[K#{message}"
      else
        puts
      end
    end

    # 静态方法：创建带回调的进度条
    def self.with_progress(total, **options)
      bar = new(total, **options)
      bar.start
      
      begin
        yield(bar) if block_given?
      ensure
        bar.finish
      end
      
      bar
    end

    # 多进度条管理器
    class MultiProgress
      def initialize
        @bars = []
        @active = false
      end

      def add(title, total, **options)
        bar = ProgressBar.new(total, title: title, **options)
        @bars << bar
        bar
      end

      def start
        @active = true
        render_all
      end

      def render_all
        return unless @active
        
        print "\e[#{@bars.length}A" unless @bars.empty? # 移动光标到顶部
        
        @bars.each_with_index do |bar, index|
          bar_output = render_bar_line(bar)
          puts "\e[K#{bar_output}"
        end
        
        $stdout.flush
      end

      def finish_all
        @active = false
        puts
      end

      private

      def render_bar_line(bar)
        bar_content = bar.send(:render_bar)
        status_text = bar.send(:render_status)
        
        output = ""
        output << "\e[94m#{bar.instance_variable_get(:@title)}: \e[0m" if bar.instance_variable_get(:@title)
        output << bar_content
        output << " #{status_text}" unless status_text.empty?
        output
      end
    end

    private

    def render_bar
      style_config = STYLES[@style] || STYLES[:default]
      
      completed_width = (@progress.to_f / @total * @width).round
      
      if @style == :gradient
        filled_chars = style_config[:filled]
        filled_full = filled_chars.last * (completed_width / filled_chars.length)
        filled_partial = filled_chars[completed_width % filled_chars.length] if completed_width % filled_chars.length > 0
        filled = filled_full + (filled_partial || '')
        empty = style_config[:empty] * (@width - filled.length)
      else
        filled = style_config[:filled] * completed_width
        empty = style_config[:empty] * (@width - completed_width)
      end
      
      # 添加颜色
      color_filled = completed? ? "\e[92m" : "\e[96m"  # 完成时绿色，进行中蓝色
      color_empty = "\e[90m"  # 空白部分灰色
      color_reset = "\e[0m"
      
      "#{style_config[:prefix]}#{color_filled}#{filled}#{color_empty}#{empty}#{color_reset}#{style_config[:suffix]}"
    end

    def render_status
      parts = []
      
      if @show_percentage
        parts << "#{percentage}%"
      end
      
      parts << "(#{@progress}/#{@total})"
      
      if @show_rate && rate > 0
        parts << sprintf("%.1f/s", rate)
      end
      
      if @show_eta && eta > 0 && !completed?
        eta_formatted = format_time(eta)
        parts << "ETA: #{eta_formatted}"
      end
      
      if @start_time
        elapsed_formatted = format_time(elapsed_time)
        parts << "#{elapsed_formatted}"
      end
      
      parts.join(" ")
    end

    def format_time(seconds)
      if seconds < 60
        sprintf("%.1fs", seconds)
      elsif seconds < 3600
        minutes = seconds / 60
        sprintf("%.1fm", minutes)
      else
        hours = seconds / 3600
        sprintf("%.1fh", hours)
      end
    end
  end
end