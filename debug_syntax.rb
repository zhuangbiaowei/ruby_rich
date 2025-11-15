#!/usr/bin/env ruby

require_relative 'lib/ruby_rich'

# Debug Rouge syntax highlighting
code = "def hello\n  puts 'world'\nend"

puts "Original code:"
puts code

puts "\nTesting Rouge directly:"
lexer = Rouge::Lexer.find('ruby')
puts "Lexer found: #{lexer.class}"

tokens = lexer.lex(code)
puts "\nTokens:"
tokens.each do |token, value|
  puts "#{token.qualname}: '#{value.inspect}'"
end

puts "\nTesting our syntax highlighter:"
result = RubyRich.syntax(code, 'ruby')
puts result

puts "\nRaw bytes of result:"
puts result.bytes.inspect