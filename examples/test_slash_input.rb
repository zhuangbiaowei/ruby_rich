#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

items = [
  { label: 'Help', value: '/help', description: 'Show available commands' },
  { label: 'Status', value: '/status', description: 'Print current status' },
  { label: 'Deploy', value: '/deploy', description: 'Run deployment flow' },
  { label: 'Test', value: '/test', description: 'Execute test suite' }
]

selected_item = nil
submitted_value = nil

slash_input = RubyRich::SlashInput.new(
  prompt: 'Command> ',
  items: items,
  width: 80,
  on_select: lambda { |item, _live|
    selected_item = item
  },
  on_submit: lambda { |value, _live|
    submitted_value = value
  }
)

puts 'Testing SlashInput:'
puts '=' * 50

# Type "/st" to filter to Status
slash_input.handle_key(name: :string, value: '/')
slash_input.handle_key(name: :string, value: 's')
slash_input.handle_key(name: :string, value: 't')

puts "\nAfter typing '/st':"
puts slash_input.render

# Select the first match with Enter
slash_input.handle_key(name: :enter)

puts "\nAfter pressing Enter to select a command:"
puts slash_input.render
puts "Selected item: #{selected_item&.dig(:label) || '(none)'}"
puts "Current value: #{slash_input.value.inspect}"

# Submit selected command
slash_input.handle_key(name: :enter)
puts "Submitted value: #{submitted_value.inspect}"

puts "\nSlashInput test completed!"
