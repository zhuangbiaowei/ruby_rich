# frozen_string_literal: true

module RubyRich
  class Sidebar
    attr_accessor :width, :height
    attr_reader :plan, :tasks

    def initialize(plan: "", tasks: [])
      @plan = plan
      @tasks = tasks
      @width = 0
      @height = 0
      @focused = false
    end

    def focus
      @focused = true
      self
    end

    def blur
      @focused = false
      self
    end

    def update_plan(text)
      @plan = text.to_s
      self
    end

    def set_tasks(tasks)
      @tasks = tasks
      self
    end

    def add_task(label, status: :pending)
      @tasks << { label: label, status: status }
      self
    end

    def render
      plan_height = [(@height * 0.48).floor, 3].max
      tasks_height = [@height - plan_height, 3].max
      [
        *panel_lines("Plan", @plan, plan_height),
        *panel_lines("Tasks", render_tasks, tasks_height)
      ].first(@height)
    end

    private

    def panel_lines(title, content, height)
      panel = Panel.new(content, title: title, border_style: @focused ? :green : :blue, title_align: :left)
      panel.width = @width
      panel.height = height
      panel.render
    end

    def render_tasks
      return "No active tasks" if @tasks.empty?

      @tasks.map do |task|
        case task
        when Hash
          "#{status_marker(task[:status])} #{task[:label]} #{AnsiCode.color(:black, true)}#{task[:status]}#{AnsiCode.reset}"
        else
          "• #{task}"
        end
      end.join("\n")
    end

    def status_marker(status)
      case status
      when :done, :completed
        "#{AnsiCode.color(:green, true)}✓#{AnsiCode.reset}"
      when :running, :in_progress
        "#{AnsiCode.color(:blue, true)}●#{AnsiCode.reset}"
      when :failed, :error
        "#{AnsiCode.color(:red, true)}!#{AnsiCode.reset}"
      else
        "#{AnsiCode.color(:black, true)}○#{AnsiCode.reset}"
      end
    end
  end
end
