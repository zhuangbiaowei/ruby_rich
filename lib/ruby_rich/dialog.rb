module RubyRich
  class Dialog
    attr_accessor :title, :content, :buttons

    def initialize(title: "", content: "", buttons: ["OK"])
      @title = title
      @content = content
      @buttons = buttons
      @selected_index = 0
      @result = nil
    end

    # 主显示方法
    def show
      Console.raw do
        loop do
          Console.clear
          render
          handle_input(Console.get_key)
          break if @result
        end
      end
      @result
    end

    private

    # 渲染对话框
    def render
      build_layout unless @layout
      update_panels
      @layout.draw
    end

    def build_layout
      @layout = RubyRich::Layout.new
      @layout.split_column(
        RubyRich::Layout.new(size: 1, name: :title_area),  # 标题区域
        RubyRich::Layout.new(name: :content_area),         # 内容区域
        RubyRich::Layout.new(size: 3, name: :button_area)  # 按钮区域
      )

      @title_panel = RubyRich::Panel.new("", title: @title, border_style: :white)
      @content_panel = RubyRich::Panel.new("", border_style: :default)
      @button_panel = RubyRich::Panel.new("", border_style: :blue)

      @layout[:title_area].update_content(@title_panel)
      @layout[:content_area].update_content(@content_panel)
      @layout[:button_area].update_content(@button_panel)
    end

    def update_panels
      # 更新内容面板
      @content_panel.content = @content.lines.map { |line|
        line.chomp.gsub(/\n/, ' ').scan(/.{1,#{@content_panel.inner_width}}/)
      }.flatten.join("\n")

      # 更新按钮面板
      button_row = @buttons.each_with_index.map { |btn, i|
        i == @selected_index ? "[#{btn}]" : " #{btn} "
      }.join("  ")

      @button_panel.content = button_row.center(@button_panel.inner_width)
    end

    # 渲染按钮区域
    def render_buttons(right_x, bottom_y)
      # 已通过布局系统处理按钮渲染
    end

    # 处理键盘输入
    def handle_input(key)
      case key
      when :left then @selected_index = (@selected_index - 1) % @buttons.size
      when :right then @selected_index = (@selected_index + 1) % @buttons.size
      when :enter then @result = @buttons[@selected_index]
      when :q, "\u0003" then @result = :cancel # Ctrl+C
      end
    end
  end

  # 确认对话框
  class ConfirmDialog < Dialog
    def initialize(title: "确认", content: "确定要执行此操作吗？")
      super(
        title: title,
        content: content,
        buttons: ["取消", "确定"]
      )
    end
  end

  # 输入对话框
  class InputDialog < Dialog
    def initialize(title: "输入", prompt: "请输入：")
      super(title: title, buttons: ["确定"])
      @input = ""
      @prompt = prompt
    end

    private

    def build_layout
      super
      # 在内容区域下方添加输入行
      @layout[:content_area].split_column(
        RubyRich::Layout.new(ratio: 1, name: :main_content),
        RubyRich::Layout.new(size: 3, name: :input_line)
      )

      @input_panel = RubyRich::Panel.new("", border_style: :yellow)
      @layout[:input_line].update_content(@input_panel)
    end

    def update_panels
      super
      @input_panel.content = "#{@prompt}#{@input}"
    end

    def handle_input(key)
      case key
      when String
        @input << key
      when :backspace
        @input.chop!
      else
        super
      end
    end

    def show
      super
      @result == "确定" ? @input : nil
    end
  end
end