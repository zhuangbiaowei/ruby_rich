# frozen_string_literal: true

# Load all dependency gems
require 'rouge'
require 'tty-cursor'
require 'tty-screen'
require 'redcarpet'

# Load all internal modules
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

# Define main module
module RubyRich
  class Error < StandardError; end

  # Provide a convenient method to create console instance
  def self.console
    @console ||= Console.new
  end

  # Provide a convenient method to create rich text
  def self.text(content = '')
    RichText.new(content)
  end

  # Provide a convenient method to create table
  def self.table(border_style: :none)
    Table.new(border_style: border_style)
  end

  # Provide a convenient method for syntax highlighting
  def self.syntax(code, language = nil, theme: :default)
    Syntax.highlight(code, language, theme: theme)
  end

  # Provide a convenient method to render Markdown
  def self.markdown(text, options = {})
    Markdown.render(text, options)
  end

  # Provide a convenient method to create tree structure
  def self.tree(root_name = 'Root', style: :default)
    Tree.new(root_name, style: style)
  end

  # Provide a convenient method to create multi-column layout
  def self.columns(total_width: 80, gutter_width: 2)
    Columns.new(total_width: total_width, gutter_width: gutter_width)
  end

  # Provide a convenient method to create status indicator
  def self.status(type, **options)
    Status.indicator(type, **options)
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
