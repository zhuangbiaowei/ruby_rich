#!/usr/bin/env ruby

require_relative '../lib/ruby_rich'

console = RubyRich::Console.new

puts "Testing Rich Markup Language Support:"
puts "=" * 50

# Test basic colors
console.print("[red]This is red text[/red]")
console.print("[green]This is green text[/green]")
console.print("[blue]This is blue text[/blue]")

# Test text styles
console.print("[bold]This is bold text[/bold]")
console.print("[italic]This is italic text[/italic]")
console.print("[underline]This is underlined text[/underline]")

# Test combined styles
console.print("[bold red]This is bold red text[/bold red]")
console.print("[italic green]This is italic green text[/italic green]")
console.print("[underline blue]This is underlined blue text[/underline blue]")

# Test bright colors
console.print("[bright_yellow]This is bright yellow text[/bright_yellow]")
console.print("[bright_cyan]This is bright cyan text[/bright_cyan]")

# Test using RichText.markup directly
puts "\nUsing RichText.markup directly:"
puts RubyRich::RichText.markup("[bold green]Success![/bold green] Operation completed [dim]successfully[/dim].")
puts RubyRich::RichText.markup("[red]Error:[/red] [italic]Something went wrong[/italic]")

# Test complex markup
console.print("[bold]Status Report:[/bold] [green]All systems operational[/green]. [dim]Last updated: 2024-01-01[/dim]")

puts "\nTesting completed!"