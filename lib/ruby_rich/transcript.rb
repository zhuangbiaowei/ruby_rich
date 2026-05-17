# frozen_string_literal: true

module RubyRich
  class Transcript
    ENTRY_TYPES = [
      :user,
      :assistant,
      :thinking,
      :tool,
      :tool_result,
      :system,
      :error,
      :markdown,
      :diff,
      :separator,
      :progress
    ].freeze

    class Entry
      attr_accessor :id, :type, :content, :metadata, :status, :collapsed, :name
      attr_reader :version

      def initialize(id:, type:, content: "", metadata: {}, status: nil, collapsed: false, name: nil)
        @id = id
        @type = type
        @content = +content.to_s
        @metadata = metadata.dup
        @status = status
        @collapsed = collapsed
        @name = name
        @version = 0
        @render_cache = {}
      end

      def text
        @content
      end

      def text=(value)
        replace(value)
      end

      def content=(value)
        replace(value)
      end

      def metadata=(value)
        @metadata = (value || {}).dup
        touch
      end

      def status=(value)
        @status = value
        touch
      end

      def collapsed=(value)
        @collapsed = value
        touch
      end

      def name=(value)
        @name = value
        touch
      end

      def append(delta)
        @content << delta.to_s
        touch
        self
      end

      def replace(new_content)
        @content = +new_content.to_s
        touch
        self
      end

      def update
        yield self
        touch
        self
      end

      def [](key)
        case key.to_sym
        when :text, :content
          @content
        when :id
          @id
        when :type
          @type
        when :metadata
          @metadata
        when :status
          @status
        when :collapsed
          @collapsed
        when :name
          @name
        else
          @metadata[key] || @metadata[key.to_sym] || @metadata[key.to_s]
        end
      end

      def []=(key, value)
        case key.to_sym
        when :text, :content
          replace(value)
        when :type
          @type = value
          touch
        when :metadata
          @metadata = value || {}
          touch
        when :status
          @status = value
          touch
        when :collapsed
          @collapsed = value
          touch
        when :name
          @name = value
          touch
        else
          @metadata[key] = value
          touch
        end
      end

      def cache_fetch(cache_key)
        versioned_key = [@version, cache_key]
        return @render_cache[versioned_key] if @render_cache.key?(versioned_key)

        @render_cache.clear
        @render_cache[versioned_key] = yield
      end

      def to_h
        {
          id: @id,
          type: @type,
          text: @content,
          content: @content,
          metadata: @metadata,
          status: @status,
          collapsed: @collapsed,
          name: @name
        }.compact
      end

      private

      def touch
        @version += 1
        @render_cache.clear
      end
    end

    class Store
      include Enumerable

      attr_reader :entries

      def initialize
        @entries = []
        @sequence = 0
        @mutex = Mutex.new
      end

      def add(type:, content: "", metadata: {}, status: nil, collapsed: nil, id: nil, name: nil)
        normalized_type = normalize_type(type)
        collapsed = default_collapsed(normalized_type) if collapsed.nil?

        @mutex.synchronize do
          entry = Entry.new(
            id: id || next_id(normalized_type),
            type: normalized_type,
            content: content,
            metadata: metadata,
            status: status,
            collapsed: collapsed,
            name: name
          )
          @entries << entry
          entry
        end
      end

      def append(id, delta)
        mutate(id) { |entry| entry.append(delta) }
      end

      def replace(id, new_content)
        mutate(id) { |entry| entry.replace(new_content) }
      end

      def remove(id)
        @mutex.synchronize do
          index = @entries.index { |entry| entry.id == id }
          return false unless index

          @entries.delete_at(index)
          true
        end
      end

      def update(id)
        mutate(id) { |entry| entry.update { |target| yield target } }
      end

      def find(id)
        @mutex.synchronize { @entries.find { |entry| entry.id == id } }
      end

      def index(id)
        @mutex.synchronize { @entries.index { |entry| entry.id == id } }
      end

      def expand(id)
        update(id) { |entry| entry.collapsed = false }
      end

      def collapse(id)
        update(id) { |entry| entry.collapsed = true }
      end

      def toggle(id)
        update(id) { |entry| entry.collapsed = !entry.collapsed }
      end

      def each(&block)
        @entries.each(&block)
      end

      private

      def mutate(id)
        @mutex.synchronize do
          entry = @entries.find { |item| item.id == id }
          return false unless entry

          yield entry
          true
        end
      end

      def normalize_type(type)
        normalized = type.to_sym
        normalized = :tool if normalized == :tool_call
        return normalized if ENTRY_TYPES.include?(normalized)

        :system
      end

      def default_collapsed(type)
        [:thinking, :tool, :tool_result].include?(type)
      end

      def next_id(type)
        @sequence += 1
        "#{type}-#{@sequence}"
      end
    end

    attr_accessor :width, :height
    attr_reader :store

    def initialize(store: Store.new)
      @store = store
      @width = 0
      @height = 0
      @selected_collapsible_id = nil
      @focused = true
    end

    def blocks
      @store.entries
    end

    def focus
      @focused = true
      self
    end

    def blur
      @focused = false
      self
    end

    def attach(layout, priority: 150)
      [:ctrl_o, :alt_v].each do |event_name|
        layout.key(event_name, priority) do |event_data, _live|
          handle_event(event_data)
          false
        end
      end

      self
    end

    def handle_event(event_data)
      return false unless @focused

      case event_data[:name]
      when :ctrl_o
        toggle_next_collapsible
      when :alt_v
        toggle_next(:tool)
      end
    end

    def add_user(text, **options)
      add_block(:user, text, **options)
    end

    def add_assistant(text, **options)
      add_block(:assistant, text, **options)
    end

    def add_thinking(text, status: "idle", collapsed: true, **options)
      add_block(:thinking, text, status: status, collapsed: collapsed, **options)
    end

    def add_tool(name, status: :running, result: nil, collapsed: false, **options)
      metadata = (options.delete(:metadata) || {}).merge(name: name)
      add_block(:tool, result.to_s, name: name, status: status, collapsed: collapsed, metadata: metadata, **options)
    end

    def add_separator(label = nil, **options)
      add_block(:separator, label.to_s, **options)
    end

    def add_markdown(text, **options)
      add_block(:markdown, text, **options)
    end

    def add_block(type, text = "", **options)
      id = options.delete(:id)
      status = options.delete(:status)
      collapsed = options.delete(:collapsed)
      name = options.delete(:name)
      metadata = options.delete(:metadata) || options
      @store.add(
        type: type,
        content: text,
        id: id,
        status: status,
        collapsed: collapsed,
        metadata: metadata,
        name: name
      ).id
    end

    def append_block(id, delta)
      @store.append(id, delta)
    end

    def replace_block(id, text, **options)
      return false unless @store.replace(id, text)
      return true if options.empty?

      @store.update(id) do |entry|
        options.each do |key, value|
          entry[key] = value
        end
      end
    end

    def remove_block(id)
      removed = @store.remove(id)
      @selected_collapsible_id = nil if removed && @selected_collapsible_id == id
      removed
    end

    def find_block(id)
      @store.find(id)
    end

    def expand_entry(id)
      @store.expand(id)
    end

    def collapse_entry(id)
      @store.collapse(id)
    end

    def toggle_entry(id)
      @store.toggle(id)
    end

    def render
      lines = []
      @store.entries.each_with_index do |entry, index|
        lines.concat(render_entry(entry, index))
      end
      lines
    end

    private

    def render_entry(entry, index)
      case entry.type
      when :user
        render_plain_message(entry.content, first_prefix: "#{AnsiCode.color(:blue, true)}●#{AnsiCode.reset} ", rest_prefix: "  ")
      when :assistant
        render_plain_message(entry.content, first_prefix: "  ", rest_prefix: "  ")
      when :thinking
        render_thinking(entry)
      when :tool
        render_tool(entry)
      when :tool_result
        render_tool_result(entry)
      when :system
        wrap_with_prefix(entry.content, "#{AnsiCode.color(:black, true)}system#{AnsiCode.reset} ")
      when :error
        wrap_with_prefix(entry.content, "#{AnsiCode.color(:red, true)}error#{AnsiCode.reset} ")
      when :separator
        [separator_line(entry.content)]
      when :markdown
        render_markdown(entry)
      when :diff
        render_diff(entry)
      when :progress
        render_progress(entry)
      else
        entry.content.to_s.split("\n", -1)
      end
    end

    def render_plain_message(content, first_prefix:, rest_prefix:)
      lines = content.to_s.split("\n", -1)
      lines = [""] if lines.empty?
      lines.each_with_index.flat_map do |line, index|
        prefix = index.zero? ? first_prefix : rest_prefix
        wrap_line(line, [@width - visible_width(prefix), 20].max).map { |part| prefix + part }
      end
    end

    def render_thinking(entry)
      status = entry.status || "idle"
      header = "#{AnsiCode.color(:white, true)}... thinking #{status}#{AnsiCode.reset}"
      return [header, "#{AnsiCode.italic}thinking collapsed; press Ctrl+O for full text#{AnsiCode.reset}"] if entry.collapsed

      [header] + wrap_with_prefix(entry.content, "#{AnsiCode.color(:black, true)}│#{AnsiCode.reset} ")
    end

    def render_tool(entry)
      ToolBlock.new(entry, width: @width).render
    end

    def render_tool_result(entry)
      status = entry.status || :done
      header = "#{AnsiCode.color(:cyan, true)}• result #{status}#{AnsiCode.reset}"
      return [header, "  result collapsed; press Ctrl+O for full output"] if entry.collapsed

      [header] + wrap_with_prefix(entry.content, "  ")
    end

    def render_markdown(entry)
      cache_key = [:markdown, @width]
      entry.cache_fetch(cache_key) do
        rendered = Markdown.render(entry.content, width: [@width, 20].max, table_border_style: :full)
        rendered.split("\n")
      end
    end

    def render_diff(entry)
      cache_key = [:diff, @width]
      entry.cache_fetch(cache_key) do
        entry.content.split("\n").flat_map do |line|
          color = if line.start_with?("+")
                    :green
                  elsif line.start_with?("-")
                    :red
                  elsif line.start_with?("@@")
                    :cyan
                  else
                    :white
                  end
          wrap_line(line, [@width, 20].max).map { |part| "#{AnsiCode.color(color, true)}#{part}#{AnsiCode.reset}" }
        end
      end
    end

    def render_progress(entry)
      total = entry.metadata[:total].to_f
      current = entry.metadata[:current].to_f
      percent = total.positive? ? [[current / total, 0.0].max, 1.0].min : 0.0
      width = [[@width - 20, 10].max, 40].min
      filled = (width * percent).round
      bar = ("█" * filled) + ("░" * (width - filled))
      label = entry.metadata[:label] || entry.content
      ["#{label} #{AnsiCode.color(:blue, true)}#{bar}#{AnsiCode.reset} #{(percent * 100).round}%"]
    end

    def wrap_with_prefix(text, prefix)
      text.split("\n").flat_map do |line|
        wrap_line(line, [@width - visible_width(prefix), 20].max).map { |part| prefix + part }
      end
    end

    def wrap_line(text, max_width)
      return [""] if text.empty?

      result = []
      current = +""
      current_width = 0
      text.each_char do |char|
        char_width = Unicode::DisplayWidth.of(char)
        if current_width + char_width > max_width
          result << current
          current = +""
          current_width = 0
        end
        current << char
        current_width += char_width
      end
      result << current unless current.empty?
      result
    end

    def separator_line(label)
      width = [@width, 20].max
      return "─" * width if label.empty?

      " #{label} ".center(width, "─")
    end

    def visible_width(text)
      text.to_s.gsub(/\e\[[0-9;:]*m/, "").display_width
    end

    def toggle_next_collapsible
      ids = @store.entries.select { |entry| [:thinking, :tool, :tool_result].include?(entry.type) }.map(&:id)
      toggle_next_id(ids)
    end

    def toggle_next(type)
      ids = @store.entries.select { |entry| entry.type == type }.map(&:id)
      toggle_next_id(ids)
    end

    def toggle_next_id(ids)
      return false if ids.empty?

      current_position = ids.index(@selected_collapsible_id)
      next_id = ids[current_position ? (current_position + 1) % ids.length : 0]
      @selected_collapsible_id = next_id
      @store.toggle(next_id)
    end
  end
end
