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
  def self.table
    Table.new
  end

  def self.logger=(logger)
    @logger = logger
  end
  def self.logger
    @logger ||= Logger.new($stdout).tap do |log|
      log.progname = "Ruby Rich"
    end
  end
end 