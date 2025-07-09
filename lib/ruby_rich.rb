# frozen_string_literal: true

# 加载所有依赖的 gem
require 'rouge'
require 'tty-cursor'
require 'tty-screen'
require 'redcarpet'

# 加载所有内部模块
require_relative 'ruby_rich/console'
require_relative 'ruby_rich/table'
require_relative 'ruby_rich/progress_bar'
require_relative 'ruby_rich/layout'
require_relative 'ruby_rich/live'
require_relative 'ruby_rich/text'
require_relative 'ruby_rich/print'
require_relative 'ruby_rich/panel'
require_relative 'ruby_rich/dialog'
require_relative 'ruby_rich/syntax'
require_relative 'ruby_rich/markdown'
require_relative 'ruby_rich/tree'
require_relative 'ruby_rich/columns'
require_relative 'ruby_rich/status'
require_relative 'ruby_rich/ansi_code'
require_relative 'ruby_rich/version'

# 定义主模块
module RubyRich
  class Error < StandardError; end
  
  # 提供一个便捷方法来创建控制台实例
  def self.console
    @console ||= Console.new
  end

  # 提供一个便捷方法来创建富文本
  def self.text(content = '')
    RichText.new(content)
  end

  # 提供一个便捷方法来创建表格
  def self.table(border_style: :none)
    Table.new(border_style: border_style)
  end

  # 提供一个便捷方法来进行语法高亮
  def self.syntax(code, language = nil, theme: :default)
    Syntax.highlight(code, language, theme: theme)
  end

  # 提供一个便捷方法来渲染 Markdown
  def self.markdown(text, options = {})
    Markdown.render(text, options)
  end

  # 提供一个便捷方法来创建树形结构
  def self.tree(root_name = 'Root', style: :default)
    Tree.new(root_name, style: style)
  end

  # 提供一个便捷方法来创建多列布局
  def self.columns(total_width: 80, gutter_width: 2)
    Columns.new(total_width: total_width, gutter_width: gutter_width)
  end

  # 提供一个便捷方法来创建状态指示器
  def self.status(type, **options)
    Status.indicator(type, **options)
  end
end