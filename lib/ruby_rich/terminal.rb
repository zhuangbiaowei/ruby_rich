# frozen_string_literal: true

require 'rbconfig'
require 'tty-cursor'
require_relative 'event'

module RubyRich
  class Terminal
    MOUSE_ENABLE = "\e[?1000h\e[?1002h\e[?1006h"
    MOUSE_DISABLE = "\e[?1006l\e[?1002l\e[?1000l"
    AUTOWRAP_ENABLE = "\e[?7h"
    AUTOWRAP_DISABLE = "\e[?7l"
    ALT_SCREEN_ENABLE = "\e[?1049h"
    ALT_SCREEN_DISABLE = "\e[?1049l"
    BRACKETED_PASTE_ENABLE = "\e[?2004h"
    BRACKETED_PASTE_DISABLE = "\e[?2004l"
    STD_INPUT_HANDLE = -10
    STD_OUTPUT_HANDLE = -11
    ENABLE_MOUSE_INPUT = 0x0010
    ENABLE_WINDOW_INPUT = 0x0008
    ENABLE_QUICK_EDIT_MODE = 0x0040
    ENABLE_EXTENDED_FLAGS = 0x0080
    ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200
    ENABLE_PROCESSED_OUTPUT = 0x0001
    ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
    INPUT_RECORD_SIZE = 20
    KEY_EVENT = 0x0001
    MOUSE_EVENT = 0x0002
    FROM_LEFT_1ST_BUTTON_PRESSED = 0x0001
    RIGHTMOST_BUTTON_PRESSED = 0x0002
    FROM_LEFT_2ND_BUTTON_PRESSED = 0x0004
    MOUSE_MOVED = 0x0001
    DOUBLE_CLICK = 0x0002
    MOUSE_WHEELED = 0x0004
    MOUSE_HWHEELED = 0x0008
    RIGHT_ALT_PRESSED = 0x0001
    LEFT_ALT_PRESSED = 0x0002
    RIGHT_CTRL_PRESSED = 0x0004
    LEFT_CTRL_PRESSED = 0x0008
    SHIFT_PRESSED = 0x0010

    class << self
      attr_accessor :debug_input

      def setup(mouse: false, hide_cursor: false, autowrap: true, alt_screen: false)
        capture_state
        enable_virtual_terminal_on_windows
        system('stty -echo') unless windows?
        enter_alt_screen if alt_screen
        enable_bracketed_paste
        set_autowrap(autowrap)
        print TTY::Cursor.hide if hide_cursor
        enable_mouse if mouse
      end

      def restore(mouse: false, show_cursor: true, autowrap: true, alt_screen: false)
        disable_mouse if mouse
        disable_bracketed_paste
        set_autowrap(autowrap)
        leave_alt_screen if alt_screen
        restore_virtual_terminal_on_windows
        system("stty #{@original_state}") if @original_state && !windows?
        print TTY::Cursor.show if show_cursor
      end

      def enable_mouse
        @mouse_reporting_enabled = true
        enable_windows_input_mode if windows?
        print MOUSE_ENABLE
        $stdout.flush
      end

      def disable_mouse
        @mouse_reporting_enabled = false
        print MOUSE_DISABLE
        $stdout.flush
      end

      def set_autowrap(enabled)
        print(enabled ? AUTOWRAP_ENABLE : AUTOWRAP_DISABLE)
        $stdout.flush
      end

      def enter_alt_screen
        print ALT_SCREEN_ENABLE
        $stdout.flush
      end

      def leave_alt_screen
        print ALT_SCREEN_DISABLE
        $stdout.flush
      end

      def enable_bracketed_paste
        print BRACKETED_PASTE_ENABLE
        $stdout.flush
      end

      def disable_bracketed_paste
        print BRACKETED_PASTE_DISABLE
        $stdout.flush
      end

      def clear
        print "\e[2J\e[H"
        $stdout.flush
      end

      def with_cooked(mouse: false, alt_screen: false)
        restore(mouse: mouse, alt_screen: alt_screen)
        yield
      ensure
        setup(mouse: mouse, alt_screen: alt_screen, autowrap: false)
      end

      def prepare_input
        return unless windows?

        enable_windows_input_mode
      end

      def windows_input_mode
        return nil unless windows?

        console_mode(get_std_handle.call(STD_INPUT_HANDLE))
      rescue
        nil
      end

      def windows?
        RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      end

      def windows_mouse_reporting?
        windows? && @mouse_reporting_enabled
      end

      def read_windows_input_event
        return nil unless windows?
        pending = next_windows_pending_event
        return pending if pending

        enable_windows_input_mode
        handle = get_std_handle.call(STD_INPUT_HANDLE)
        record = Fiddle::Pointer.malloc(INPUT_RECORD_SIZE)
        read_count = Fiddle::Pointer.malloc(4)

        loop do
          return nil unless read_console_input.call(handle, record, 1, read_count) != 0
          next unless read_count[0, 4].unpack1('L') == 1

          event = parse_windows_input_record(record)
          event = coalesce_windows_paste(handle, event) if paste_seed_event?(event)
          return event if event
        end
      rescue
        nil
      end

      private

      def capture_state
        @original_state = windows? ? nil : `stty -g`.strip
      rescue
        @original_state = nil
      end

      def enable_virtual_terminal_on_windows
        return unless windows?

        @windows_console_modes ||= {}

        enable_windows_output_mode
        enable_windows_input_mode
      rescue
        nil
      end

      def enable_windows_output_mode
        handle = get_std_handle.call(STD_OUTPUT_HANDLE)
        mode = console_mode(handle)
        return unless mode

        @windows_console_modes ||= {}
        @windows_console_modes[handle.to_i] ||= { handle: handle, mode: mode }
        set_console_mode.call(handle, mode | ENABLE_PROCESSED_OUTPUT | ENABLE_VIRTUAL_TERMINAL_PROCESSING)
      end

      def enable_windows_input_mode
        handle = get_std_handle.call(STD_INPUT_HANDLE)
        mode = console_mode(handle)
        return unless mode

        @windows_console_modes ||= {}
        @windows_console_modes[handle.to_i] ||= { handle: handle, mode: mode }
        next_mode = mode
        next_mode |= ENABLE_EXTENDED_FLAGS
        next_mode |= ENABLE_MOUSE_INPUT
        next_mode |= ENABLE_WINDOW_INPUT
        next_mode &= ~ENABLE_QUICK_EDIT_MODE
        set_console_mode.call(handle, next_mode)
      end

      def restore_virtual_terminal_on_windows
        return unless windows?
        return unless @windows_console_modes && !@windows_console_modes.empty?

        require 'fiddle'
        kernel32 = Fiddle.dlopen('kernel32')
        set_console_mode = Fiddle::Function.new(
          kernel32['SetConsoleMode'],
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG],
          Fiddle::TYPE_INT
        )

        @windows_console_modes.each_value do |entry|
          set_console_mode.call(entry[:handle], entry[:mode])
        end
        @windows_console_modes.clear
      rescue
        nil
      end

      def console_mode(handle)
        mode_ptr = Fiddle::Pointer.malloc(4)
        return nil unless get_console_mode.call(handle, mode_ptr) != 0

        mode_ptr[0, 4].unpack1('L')
      end

      def kernel32
        @kernel32 ||= begin
          ensure_fiddle
          Fiddle.dlopen('kernel32')
        end
      end

      def get_std_handle
        ensure_fiddle
        @get_std_handle ||= Fiddle::Function.new(
          kernel32['GetStdHandle'],
          [Fiddle::TYPE_LONG],
          Fiddle::TYPE_VOIDP
        )
      end

      def get_console_mode
        ensure_fiddle
        @get_console_mode ||= Fiddle::Function.new(
          kernel32['GetConsoleMode'],
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
          Fiddle::TYPE_INT
        )
      end

      def set_console_mode
        ensure_fiddle
        @set_console_mode ||= Fiddle::Function.new(
          kernel32['SetConsoleMode'],
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG],
          Fiddle::TYPE_INT
        )
      end

      def read_console_input
        ensure_fiddle
        @read_console_input ||= Fiddle::Function.new(
          kernel32['ReadConsoleInputW'],
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG, Fiddle::TYPE_VOIDP],
          Fiddle::TYPE_INT
        )
      end

      def get_number_of_console_input_events
        ensure_fiddle
        @get_number_of_console_input_events ||= Fiddle::Function.new(
          kernel32['GetNumberOfConsoleInputEvents'],
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
          Fiddle::TYPE_INT
        )
      end

      def parse_windows_input_record(record)
        event_type = record[0, 2].unpack1('S')

        case event_type
        when KEY_EVENT
          parse_windows_key_record(record)
        when MOUSE_EVENT
          parse_windows_mouse_record(record)
        end
      end

      def next_windows_pending_event
        return nil unless @windows_pending_events && !@windows_pending_events.empty?

        @windows_pending_events.shift
      end

      def paste_seed_event?(event)
        event && event[:type] == :key && [:string, :enter, :tab].include?(event[:name])
      end

      def coalesce_windows_paste(handle, first_event)
        events = [first_event]
        sleep 0.002
        available = windows_input_event_count(handle)

        while available && available.positive?
          record = Fiddle::Pointer.malloc(INPUT_RECORD_SIZE)
          read_count = Fiddle::Pointer.malloc(4)
          break unless read_console_input.call(handle, record, 1, read_count) != 0
          break unless read_count[0, 4].unpack1('L') == 1

          event = parse_windows_input_record(record)
          if paste_seed_event?(event)
            events << event
          elsif event
            (@windows_pending_events ||= []) << event
          end
          available = windows_input_event_count(handle)
        end

        finish_windows_coalesced_events(events, first_event)
      rescue
        first_event
      end

      def finish_windows_coalesced_events(events, first_event)
        if windows_enter_burst?(events)
          first_event
        elsif windows_paste_burst?(events)
          Event.key(:paste, value: events.map { |event| windows_paste_text(event) }.join)
        else
          (@windows_pending_events ||= []).concat(events[1..] || [])
          first_event
        end
      end

      def windows_enter_burst?(events)
        events.length <= 2 && events.all? { |event| event[:name] == :enter }
      end

      def windows_paste_burst?(events)
        return false if events.length <= 1

        events.any? { |event| event[:name] == :enter } || events.length >= 4
      end

      def windows_paste_text(event)
        case event[:name]
        when :string
          event[:value].to_s
        when :enter
          "\n"
        when :tab
          "\t"
        else
          ""
        end
      end

      def windows_input_event_count(handle)
        count_ptr = Fiddle::Pointer.malloc(4)
        return nil unless get_number_of_console_input_events.call(handle, count_ptr) != 0

        count_ptr[0, 4].unpack1('L')
      end

      def parse_windows_key_record(record)
        key_down = record[4, 4].unpack1('L') != 0
        return nil unless key_down

        virtual_key = record[10, 2].unpack1('S')
        control_state = record[12, 4].unpack1('L')
        char_code = record[14, 2].unpack1('S')
        char = char_code.zero? ? nil : char_code.chr(Encoding::UTF_8)
        modifiers = windows_key_modifiers(control_state)

        case virtual_key
        when 13
          return annotate_windows_key_event(Event.key(:alt_enter), virtual_key, char_code, control_state, modifiers) if modifiers.include?(:alt)
          return annotate_windows_key_event(Event.key(:ctrl_enter), virtual_key, char_code, control_state, modifiers) if char_code == 10 && modifiers.include?(:ctrl)
          return annotate_windows_key_event(Event.key(:shift_enter), virtual_key, char_code, control_state, modifiers) if char_code == 10

          annotate_windows_key_event(Event.key(:enter), virtual_key, char_code, control_state, modifiers)
        when 9
          modifiers.include?(:shift) ? Event.key(:shift_tab) : Event.key(:tab)
        when 8 then Event.key(:backspace)
        when 27 then Event.key(:escape)
        when 37 then Event.key(:left)
        when 38 then Event.key(:up)
        when 39 then Event.key(:right)
        when 40 then Event.key(:down)
        when 33 then Event.key(:page_up)
        when 34 then Event.key(:page_down)
        when 35 then Event.key(:end)
        when 36 then Event.key(:home)
        when 46 then Event.key(:delete)
        else
          ctrl_event = windows_ctrl_key_event(char_code)
          return ctrl_event if ctrl_event
          return Event.key(:ctrl_c) if char_code == 3
          return nil unless char && !char.empty?

          Event.key(:string, value: char)
        end
      rescue RangeError
        nil
      end

      def parse_windows_mouse_record(record)
        raw_x = record[4, 2].unpack1('s')
        raw_y = record[6, 2].unpack1('s')
        button_state = record[8, 4].unpack1('L')
        control_state = record[12, 4].unpack1('L')
        event_flags = record[16, 4].unpack1('L')

        if (event_flags & MOUSE_WHEELED) == MOUSE_WHEELED
          delta = signed_high_word(button_state)
          return Event.mouse(
            :mouse_wheel,
            button: :wheel,
            x: raw_x,
            y: raw_y,
            raw_x: raw_x + 1,
            raw_y: raw_y + 1,
            code: button_state,
            modifiers: windows_mouse_modifiers(control_state),
            direction: delta.negative? ? :down : :up
          )
        end

        if (event_flags & MOUSE_MOVED) == MOUSE_MOVED
          return nil if button_state.zero?

          return windows_mouse_event(:mouse_drag, raw_x, raw_y, button_state, control_state)
        end

        if button_state.zero?
          return windows_mouse_event(:mouse_up, raw_x, raw_y, button_state, control_state)
        end

        windows_mouse_event(:mouse_down, raw_x, raw_y, button_state, control_state)
      end

      def windows_mouse_event(name, raw_x, raw_y, button_state, control_state)
        Event.mouse(
          name,
          button: windows_mouse_button(button_state),
          x: raw_x,
          y: raw_y,
          raw_x: raw_x + 1,
          raw_y: raw_y + 1,
          code: button_state,
          modifiers: windows_mouse_modifiers(control_state)
        )
      end

      def windows_mouse_button(button_state)
        return :left if (button_state & FROM_LEFT_1ST_BUTTON_PRESSED) != 0
        return :right if (button_state & RIGHTMOST_BUTTON_PRESSED) != 0
        return :middle if (button_state & FROM_LEFT_2ND_BUTTON_PRESSED) != 0

        :unknown
      end

      def windows_mouse_modifiers(control_state)
        windows_key_modifiers(control_state)
      end

      def windows_key_modifiers(control_state)
        modifiers = []
        modifiers << :shift if (control_state & SHIFT_PRESSED) != 0
        modifiers << :ctrl if (control_state & LEFT_CTRL_PRESSED) != 0 || (control_state & RIGHT_CTRL_PRESSED) != 0
        modifiers << :alt if (control_state & LEFT_ALT_PRESSED) != 0 || (control_state & RIGHT_ALT_PRESSED) != 0
        modifiers
      end

      def windows_ctrl_key_event(char_code)
        return nil unless char_code.between?(1, 26)

        ctrl_char = (char_code + 64).chr.downcase
        Event.key("ctrl_#{ctrl_char}".to_sym)
      end

      def annotate_windows_key_event(event, virtual_key, char_code, control_state, modifiers)
        return event unless @debug_input

        event.merge(
          raw: {
            virtual_key: virtual_key,
            char_code: char_code,
            control_state: control_state,
            modifiers: modifiers
          }
        )
      end

      def signed_high_word(value)
        high = (value >> 16) & 0xffff
        high >= 0x8000 ? high - 0x10000 : high
      end

      def ensure_fiddle
        require 'fiddle'
      end
    end
  end
end
