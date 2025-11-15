#!/usr/bin/env ruby

puts "Testing basic ANSI colors:"
puts "\e[31mRed text\e[0m"
puts "\e[32mGreen text\e[0m"
puts "\e[33mYellow text\e[0m"
puts "\e[34mBlue text\e[0m"
puts "\e[94mBright Blue text\e[0m"
puts "\e[96mBright Cyan text\e[0m"

puts "\nTesting syntax highlighting colors:"
require_relative '../lib/ruby_rich'

code = "def hello\n  puts 'world'\nend"
highlighted = RubyRich.syntax(code, 'ruby')
puts highlighted