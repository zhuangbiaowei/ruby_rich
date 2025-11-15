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