#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/ruby_rich"

class CompleteAgentDemo
  def initialize(smoke: false)
    @smoke = smoke
    @shell = RubyRich::AgentShell.new(
      title: "OpenClacky",
      subtitle: "RubyRich Agent TUI complete demo",
      model: "gpt-5.4",
      theme: RubyRich::Theme.auto
    )
    @events = []
    configure_callbacks
    configure_commands
    seed_transcript
  end

  def run
    return run_smoke if @smoke

    start_background_activity
    @shell.start(refresh_rate: 60, mouse: true, alt_screen: true)
  end

  private

  def configure_callbacks
    @shell.on_submit do |text, attachments|
      @events << [:submit, text, attachments.length]
      next if text.start_with?("/")

      @shell.add_user_message(text)
      response = @shell.add_assistant_message("", streaming: true)
      "Echo: #{text}".chars.each_slice(4) do |slice|
        @shell.append_to_message(response, slice.join)
      end
      @shell.show_token_usage(input: text.length, output: @shell.transcript.find_block(response).content.length)
    end

    @shell.on_interrupt do
      @events << [:interrupt]
      @shell.update_status("interrupt requested")
    end

    @shell.on_mode_toggle do |mode|
      @events << [:mode, mode]
      @shell.update_status("mode switched to #{mode}")
    end

    @shell.on_command do |command|
      @events << [:command, command]
    end
  end

  def configure_commands
    composer = @shell.composer

    composer.register_command(
      name: "/config",
      description: "Open configuration form",
      aliases: ["/settings"],
      group: "system",
      handler: lambda do |_args|
        values = @shell.form(
          title: "Configuration",
          fields: [
            { name: :api_key, type: :password },
            { name: :model, type: :select, options: ["gpt-5.2", "gpt-5.4"], default: "gpt-5.4" },
            { name: :enabled, type: :boolean, default: true }
          ]
        )
        @shell.add_markdown("**Configuration defaults**\n\n```ruby\n#{values.inspect}\n```")
      end
    )

    composer.register_command(
      name: "/allow-tool",
      description: "Show confirmation API",
      group: "tools",
      handler: lambda do |_args|
        result = @shell.confirm(
          title: "Allow tool?",
          message: "Allow the Read tool to inspect a local file?",
          choices: [
            { key: "y", label: "Allow" },
            { key: "n", label: "Deny" }
          ],
          default: "n"
        )
        @shell.add_assistant_message("Confirmation result: #{result.inspect}")
      end
    )

    composer.register_command(
      name: "/progress",
      description: "Run nested unknown-duration progress",
      group: "runtime",
      handler: lambda do |_args|
        @shell.with_progress("Running outer task") do |_outer|
          sleep 0.05
          inner = @shell.start_progress("Calling model")
          sleep 0.05
          inner.update("Parsing response")
          sleep 0.05
          inner.finish("Model response parsed")
        end
        @shell.update_status("progress cleaned up")
      end
    )

    composer.register_command(
      name: "/tool",
      description: "Update one tool entry in place",
      group: "tools",
      handler: lambda do |args|
        id = @shell.start_tool_call(name: "Read", input: { path: args.empty? ? "lib/ruby_rich.rb" : args }, status: :running)
        @shell.update_tool_call(id, status: :done, output: "\e[32mRead completed\e[0m\nLong output is collapsible with Ctrl+O.")
      end
    )

    composer.register_command(
      name: "/diff",
      description: "Add diff block",
      group: "rendering",
      handler: lambda do |_args|
        @shell.add_diff(
          title: "Demo diff",
          content: <<~DIFF
            @@ ruby_rich agent shell @@
            + add AgentShell
            + add Transcript::Store
            - duplicate tool transcript rows
          DIFF
        )
      end
    )

    composer.register_command(
      name: "/pager",
      description: "Exercise external pager API with /pager open",
      group: "viewport",
      handler: lambda do |args|
        text = @shell.transcript.render.join("\n")
        if args.strip == "open"
          @shell.open_pager(text)
        else
          @shell.add_assistant_message("Pager API is ready. Run `/pager open` to invoke the configured pager.")
        end
      end
    )

    composer.register_command(name: "/hidden", hidden: true, handler: -> {})

    composer.refresh_commands_async do
      sleep 0.01
      [
        { label: "/async", value: "/async", description: "Async refreshed command", group: "runtime" },
        *composer.instance_variable_get(:@commands)
      ]
    end
  end

  def seed_transcript
    @shell.update_tasks([
      { label: "#1 AgentShell stable output API", status: :done },
      { label: "#2 Transcript::Store entry model", status: :done },
      { label: "#3 Composer + LineEditor", status: :done },
      { label: "#4 Slash commands + palette", status: :done },
      { label: "#5 Progress manager", status: :done },
      { label: "#6 Confirm/form API", status: :in_progress },
      { label: "#7 Managed viewport + pager", status: :done },
      { label: "#8 ToolBlock", status: :done },
      { label: "#9 Markdown/syntax/diff", status: :done },
      { label: "#10 Theme/capability", status: :done }
    ])
    @shell.update_status("ready · try /config, /progress, /tool, /diff, /pager")
    @shell.show_token_usage(input: 128, output: 256, total: 384)

    @shell.add_user_message("Demonstrate RubyRich Agent TUI features #1 through #10.")
    assistant_id = @shell.add_assistant_message("", streaming: true)
    @shell.append_to_message(assistant_id, "AgentShell returns stable ids, supports streaming append, replace, remove, and queues UI updates safely.")
    @shell.replace_message(assistant_id, "AgentShell returns stable ids and supports streaming append, replace, remove, and thread-safe UI dispatch.")

    store = RubyRich::Transcript::Store.new
    entry = store.add(type: :assistant, content: "", metadata: { streaming: true })
    store.append(entry.id, "Transcript::Store supports add/append/replace/remove/update.")
    store.update(entry.id) { |item| item.status = :done }
    @shell.add_markdown("### Transcript Store\n\n#{entry.content}\n\nEntry status: `#{entry.status}`", streaming: true)

    @shell.add_markdown(<<~MARKDOWN, streaming: true)
      ### Composer and LineEditor

      - Multiline input, history, Ctrl+A/E/K/U/W, Ctrl+C, Ctrl+D, paste, and attachments.
      - Unicode width is handled for CJK and emoji: `中文🙂text`.
      - Attach files with `composer.add_attachment(RubyRich::Attachment.new(...))`.

      ```ruby
      attachment = RubyRich::Attachment.new(type: :image, path: "/path/to/file.png")
      shell.composer.add_attachment(attachment)
      ```
    MARKDOWN

    @shell.composer.add_attachment(
      RubyRich::Attachment.new(
        type: :image,
        path: File.expand_path("../images/screen.png", __dir__),
        mime_type: "image/png",
        display_name: "screen.png"
      )
    )

    tool = @shell.start_tool_call(name: "Read", input: { path: "lib/ruby_rich/transcript.rb" }, status: :running)
    @shell.update_tool_call(
      tool,
      status: :done,
      output: "\e[36mFound Transcript::Store and ToolBlock rendering.\e[0m\nPress Ctrl+O while transcript is focused to expand/collapse details."
    )

    @shell.add_diff(
      title: "Markdown, Syntax, and Diff",
      content: <<~DIFF
        @@ rendering @@
        + Markdown entries cache rendered content by width and version.
        + Diff entries use dedicated coloring.
        + Streaming markdown can be appended before fences are closed.
      DIFF
    )

    @shell.add_markdown("Theme auto mode: `#{RubyRich::Theme.auto.class}`. `NO_COLOR` and `TERM=dumb` are respected by `AnsiCode`.")
  end

  def start_background_activity
    Thread.new do
      sleep 0.4
      handle = @shell.start_progress("Background ticker")
      sleep 0.4
      handle.update("Background worker updated status")
      sleep 0.4
      handle.finish("Background worker finished")
      @shell.update_status("interactive demo running")
    rescue => e
      @shell.update_status("background demo failed: #{e.message}")
    end
  end

  def run_smoke
    progress = @shell.start_progress("Smoke progress")
    progress.update("Smoke update")
    progress.finish("Smoke done")

    result = @shell.confirm(
      title: "Allow tool?",
      message: "smoke",
      choices: [{ key: "n", label: "Deny" }],
      default: "n"
    )
    values = @shell.form(
      title: "Configuration",
      fields: [
        { name: :api_key, type: :password },
        { name: :enabled, type: :boolean, default: true }
      ]
    )

    @shell.layout.calculate_dimensions(100, 32)
    rendered = @shell.layout.render

    raise "confirm failed" unless result == "n"
    raise "form failed" unless values == { api_key: "", enabled: true }
    transcript_text = @shell.transcript.render.join("\n")
    raise "missing AgentShell text" unless transcript_text.include?("AgentShell")
    raise "missing diff text" unless transcript_text.include?("Markdown")
    raise "missing command registration" unless @shell.composer.render.join("\n").include?("screen.png")

    puts "Complete Agent TUI demo smoke passed"
  end
end

if __FILE__ == $PROGRAM_NAME
  CompleteAgentDemo.new(smoke: ARGV.include?("--smoke")).run
end
