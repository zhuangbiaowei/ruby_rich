# RubyRich - Rich Terminal Text Utilities for Ruby

![RubyRich Demo](https://via.placeholder.com/800x400.png?text=RubyRich+Terminal+Demo)

A modern Ruby terminal UI toolkit inspired by Python Rich

## ✨ Features

- 🖥️ **Terminal Output** - Elegant formatted output with automatic color detection
- 📊 **Progress Bars** - Versatile progress bars with speed/time estimation
- 🧩 **Panel Layouts** - Create nested layouts with borders and styles
- 🎨 **Text Styling** - Chainable text styles with RGB/HEX color support
- 📜 **Table System** - Auto-expanding tables with column alignment
- 🖼️ **Syntax Highlighting** - Built-in support for 200+ languages
- 📈 **Status Displays** - Persistent status with live animations

## 📦 Installation

Add to Gemfile:
```ruby
gem 'ruby_rich'
```

Or install directly:
```bash
gem install ruby_rich
```

## 🚀 Quick Start

```ruby
require 'ruby_rich'

# Initialize console
console = RubyRich::Console.new

# Basic styled print
console.print("[bold green]Operation successful![/bold green] [italic]File saved[/italic]")

# Create info panel
panel = RubyRich::Panel.new(
  "[blue]System Info[/blue]\nCPU: 42%\nMemory: 38%",
  title: "Status",
  border_style: "round",
  padding: 1
)
console.print(panel)

# Generate table
table = RubyRich::Table.new("User Report", columns: 3)
table.add_row("Name", "Age", "Status")
table.add_row("[cyan]John Doe[/cyan]", "28", "[green]Active[/green]")
console.print(table)

# Progress bar usage
RubyRich::ProgressBar.new("Processing...").with_progress do |bar|
  10.times do |i|
    sleep 0.1
    bar.advance(10, desc: "Step #{i+1}")
  end
end
```

## 📚 Advanced Features

### Theme System
```ruby
theme = RubyRich::Theme.new(
  success: "bold green",
  warning: "gold1",
  error: "bold red",
  highlight: "rgb(255,215,0)"
)
console.apply_theme(theme)
```

### Layout System
```ruby
layout = RubyRich::Layout.new(
  header: "[bold]Application Dashboard[/bold]",
  footer: "[dim]Press F1 for help[/dim]",
  columns: 2
)
layout.add_column("Main Content", width: 70)
layout.add_column("Sidebar")
console.print(layout)
```

## 🤝 Contributing

1. Fork the repository
2. Create new feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -m 'Add new feature'`)
4. Push branch (`git push origin feature/new-feature`)
5. Create Pull Request

## 📄 License

MIT License - See [LICENSE](LICENSE)