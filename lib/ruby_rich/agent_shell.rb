# frozen_string_literal: true

require "thread"

module RubyRich
  class AgentShell < AppShell
    attr_reader :mode

    def initialize(**options)
      @callbacks = {}
      @state_mutex = Mutex.new
      @id_mutex = Mutex.new
      @pending_actions = Queue.new
      @entry_sequence = 0
      @state = :initialized
      @ui_thread = nil
      @mode = :chat
      super
      @stop_on_ctrl_c = false
      @composer.instance_variable_set(:@on_interrupt, method(:handle_interrupt))
      @composer.instance_variable_set(:@on_eof, method(:handle_eof))
      attach_agent_controls
    end

    def on_submit(&block)
      @callbacks[:submit] = block
      self
    end

    def on_interrupt(&block)
      @callbacks[:interrupt] = block
      self
    end

    def on_mode_toggle(&block)
      @callbacks[:mode_toggle] = block
      self
    end

    def on_command(&block)
      @callbacks[:command] = block
      self
    end

    def start(refresh_rate: 24, mouse: true, alt_screen: true)
      @state_mutex.synchronize { @state = :starting }
      Live.start(@layout, refresh_rate: refresh_rate, mouse: mouse, alt_screen: alt_screen, autowrap: false) do |live|
        @state_mutex.synchronize do
          @live = live
          @ui_thread = Thread.current
          @state = :running
        end
        drain_pending_actions(live)
        live.listening = true
      end
    ensure
      @state_mutex.synchronize do
        @live = nil
        @ui_thread = nil
        @state = :stopped
      end
    end

    def stop
      dispatch_after_start_failure = false
      @state_mutex.synchronize do
        return false if @state == :stopped

        if @live
          return @live.stop if Thread.current == @ui_thread

          return @live.post { |live| live.stop } || false
        end

        @state = :stopped
        dispatch_after_start_failure = true
      end
      dispatch_after_start_failure
    end

    def add_user_message(text)
      add_message(:user, text)
    end

    def add_assistant_message(text, streaming: false)
      add_message(:assistant, text, streaming: streaming)
    end

    def add_markdown(content, streaming: false)
      add_message(:markdown, content, streaming: streaming)
    end

    def add_system_message(text)
      add_message(:system, text)
    end

    def add_error_message(text)
      add_message(:error, text)
    end

    def add_diff(title: nil, content:, language: "diff")
      text = title ? "#{title}\n#{content}" : content
      add_message(:diff, text, language: language)
    end

    def append_to_message(id, delta)
      dispatch { @transcript.append_block(id, delta).tap { @viewport.scroll_to_bottom } }
    end

    def replace_message(id, text)
      dispatch { @transcript.replace_block(id, text).tap { @viewport.scroll_to_bottom } }
    end

    def remove_entry(id)
      dispatch { @transcript.remove_block(id).tap { @viewport.scroll_to_bottom } }
    end

    def start_tool_call(name:, input: nil, status: :running)
      id = reserve_id(:tool)
      return nil unless id

      ok = dispatch do
        @transcript.add_tool(name, status: status, result: tool_body(input: input), collapsed: false, id: id)
        @viewport.scroll_to_bottom
        id
      end
      ok ? id : nil
    end

    def update_tool_call(id, status: nil, output: nil, input: nil)
      options = {}
      options[:status] = status if status
      text = output.nil? && input.nil? ? nil : tool_body(input: input, output: output)
      dispatch do
        block = @transcript.find_block(id)
        next false unless block

        text ||= block[:text]
        @transcript.replace_block(id, text, **options).tap { @viewport.scroll_to_bottom }
      end
    end

    def finish_tool_call(id, status: :done, output: nil)
      update_tool_call(id, status: status, output: output)
    end

    def update_tasks(tasks)
      dispatch { @sidebar.set_tasks(tasks) }
    end

    def update_status(text)
      dispatch { @status = text.to_s }
    end

    def show_token_usage(input: nil, output: nil, total: nil, **extra)
      dispatch { @token_usage = { input: input, output: output, total: total }.merge(extra).compact }
    end

    def stopped?
      @state_mutex.synchronize { @state == :stopped }
    end

    private

    def add_message(type, text, **options)
      id = reserve_id(type)
      return nil unless id

      ok = dispatch do
        @transcript.add_block(type, text, **options, id: id)
        @viewport.scroll_to_bottom
        id
      end
      ok ? id : nil
    end

    def reserve_id(type)
      @state_mutex.synchronize { return nil if @state == :stopped }

      @id_mutex.synchronize do
        @entry_sequence += 1
        "#{type}-#{@entry_sequence}"
      end
    end

    def dispatch
      state, live, ui_thread = @state_mutex.synchronize { [@state, @live, @ui_thread] }
      return false if state == :stopped

      if live
        return yield if Thread.current == ui_thread

        return live.post { yield }
      end

      if state == :starting
        @pending_actions << proc { yield }
        return true
      end

      yield
    end

    def drain_pending_actions(live)
      @pending_actions.pop(true).call(live) until @pending_actions.empty?
    rescue ThreadError
      nil
    end

    def attach_agent_controls
      @layout.key(:ctrl_c, 2_000) do |_event, live|
        handle_interrupt(live, self)
        false
      end

      @layout.key(:ctrl_m, 2_000) do |_event, _live|
        toggle_mode
        false
      end
    end

    def handle_interrupt(live = nil, _source = nil)
      input_was_empty = @composer.value.to_s.empty?
      @callbacks[:interrupt]&.call(input_was_empty: input_was_empty)
      live&.stop
    end

    def handle_eof(live = nil, _source = nil)
      @callbacks[:eof]&.call if @callbacks[:eof]
      live&.stop
    end

    def handle_submit(value, live, attachments = [])
      text = value.to_s
      stripped = text.strip
      if text.start_with?("/")
        command = text.split(/\s+/, 2).first
        @callbacks[:command]&.call(command)
      end

      if stripped == "/quit"
        live&.stop
        return
      end

      @callbacks[:submit]&.call(text, attachments)
    end

    def toggle_mode
      @mode = @mode == :chat ? :agent : :chat
      @callbacks[:mode_toggle]&.call(@mode)
      @status = "mode · #{@mode}"
    end

    def tool_body(input: nil, output: nil)
      parts = []
      parts << "input:\n#{input}" unless input.nil? || input.to_s.empty?
      parts << "output:\n#{output}" unless output.nil? || output.to_s.empty?
      parts.join("\n")
    end
  end
end
