# frozen_string_literal: true

module RubyRich
  class ToolBlock
    STATES = [:pending, :running, :done, :error, :cancelled, :denied].freeze

    def initialize(entry, width: 80)
      @entry = entry
      @width = [width, 20].max
    end

    def render
      name = @entry.name || @entry.metadata[:name] || "tool"
      status = normalize_status(@entry.status || :pending)
      header = "#{AnsiCode.color(color(status), true)}• #{status_marker(status)} #{name} #{status}#{AnsiCode.reset}"
      return [header, "  #{summary(@entry.content)}", "  details collapsed; press Ctrl+O for full output"] if @entry.collapsed

      [header] + details(@entry.content)
    end

    private

    def normalize_status(status)
      status = status.to_sym
      return :error if status == :failed || status == :issue
      return status if STATES.include?(status)

      :pending
    end

    def color(status)
      case status
      when :done then :green
      when :error, :denied then :red
      when :cancelled then :yellow
      else :blue
      end
    end

    def status_marker(status)
      case status
      when :done then "✓"
      when :error then "!"
      when :cancelled then "-"
      when :denied then "x"
      else "▸"
      end
    end

    def summary(content)
      plain = content.to_s.gsub(/\e\[[0-9;:]*m/, "").split("\n").first.to_s
      plain.empty? ? "<no output>" : plain[0, [@width - 4, 20].max]
    end

    def details(content)
      text = content.to_s
      return ["  <no output>"] if text.empty?

      text.split("\n").flat_map { |line| wrap(line).map { |part| "  #{part}" } }
    end

    def wrap(line)
      max_width = [@width - 2, 20].max
      result = []
      current = +""
      width = 0
      in_escape = false
      line.each_char do |char|
        if in_escape
          current << char
          in_escape = false if char == "m"
          next
        elsif char.ord == 27
          current << char
          in_escape = true
          next
        end

        char_width = Unicode::DisplayWidth.of(char)
        if width + char_width > max_width
          result << current
          current = +""
          width = 0
        end
        current << char
        width += char_width
      end
      result << current unless current.empty?
      result
    end
  end
end
