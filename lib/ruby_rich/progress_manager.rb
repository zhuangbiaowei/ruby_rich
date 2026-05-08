# frozen_string_literal: true

require "securerandom"

module RubyRich
  class ProgressManager
    FRAMES = %w[| / - \\].freeze

    class Handle
      attr_reader :id, :owner, :message, :state

      def initialize(manager, id:, owner:, message:)
        @manager = manager
        @id = id
        @owner = owner
        @message = message
        @state = :running
      end

      def update(message)
        return false unless active?

        @message = message.to_s
        @manager.update(@id, @owner, @message)
      end

      def finish(message = "Done")
        close(:done, message)
      end

      def fail(message = "Failed")
        close(:error, message)
      end

      def cancel(message = "Cancelled")
        close(:cancelled, message)
      end

      def active?
        @state == :running
      end

      private

      def close(state, message)
        return false unless active?

        @state = state
        @message = message.to_s
        @manager.finish(@id, @owner, state, @message)
      end
    end

    def initialize(on_change: nil)
      @stack = []
      @mutex = Mutex.new
      @on_change = on_change
      @frame = 0
      @ticker = nil
      @running = false
    end

    def start(message, owner: Thread.current.object_id)
      handle = Handle.new(self, id: SecureRandom.hex(6), owner: owner, message: message.to_s)
      @mutex.synchronize { @stack << handle }
      start_ticker
      notify
      handle
    end

    def update(id, owner, message)
      ok = @mutex.synchronize do
        handle = @stack.find { |item| item.id == id && item.owner == owner && item.active? }
        next false unless handle

        handle.instance_variable_set(:@message, message.to_s)
        true
      end
      notify if ok
      ok
    end

    def finish(id, owner, state, message)
      ok = @mutex.synchronize do
        handle = @stack.find { |item| item.id == id && item.owner == owner }
        next false unless handle

        handle.instance_variable_set(:@state, state)
        handle.instance_variable_set(:@message, message.to_s)
        @stack.delete(handle)
        true
      end
      notify if ok
      stop_ticker_if_idle
      ok
    end

    def current
      @mutex.synchronize { @stack.last }
    end

    def render
      handle = current
      return nil unless handle

      frame = FRAMES[@frame % FRAMES.length]
      "#{frame} #{handle.message}"
    end

    def with_progress(message)
      handle = start(message)
      begin
        yield handle
        handle.finish
      rescue Exception => e
        handle.fail(e.message)
        raise
      ensure
        handle.cancel if handle.active?
      end
    end

    private

    def notify
      @on_change&.call(render)
    end

    def start_ticker
      return if @ticker&.alive?

      @running = true
      @ticker = Thread.new do
        while @running
          sleep 0.12
          @frame += 1
          notify
        end
      end
    end

    def stop_ticker_if_idle
      return if current

      @running = false
      @ticker&.kill
      @ticker = nil
    end
  end
end
