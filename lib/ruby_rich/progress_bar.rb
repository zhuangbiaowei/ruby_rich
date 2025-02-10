module RubyRich
  class ProgressBar
    
    attr_reader :progress

    def initialize(total, width: 50, style: :default)
      @total = total
      @progress = 0
      @width = width
      @style = style
    end

    def advance(amount)
      @progress += amount
      @progress = @total if @progress > @total
      render
    end

    def render
      percentage = (@progress.to_f / @total * 100).to_i
      completed_width = (@progress.to_f / @total * @width).to_i
      incomplete_width = @width - completed_width

      bar = "[#{"=" * completed_width}#{" " * incomplete_width}]"
      print "\r#{bar} #{percentage}%"
      puts if @progress == @total
    end
  end
end
