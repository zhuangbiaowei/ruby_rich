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
require_relative 'ruby_rich/rich_text'
require_relative 'ruby_rich/rich_print'
require_relative 'ruby_rich/rich_panel'
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
  def self.table
    Table.new
  end
end 