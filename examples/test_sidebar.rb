#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

layout = RubyRich::Layout.new(name: :root)
sidebar = RubyRich::Sidebar.new(
  plan: "tracks update_plan // /goal /cycles\n\nBuild Composer, Focus, Transcript, Sidebar.",
  tasks: [
    { label: "Composer component", status: :done },
    { label: "Focus manager", status: :done },
    { label: "Transcript blocks", status: :in_progress },
    { label: "Sidebar panel", status: :pending }
  ]
)
layout.content = sidebar

layout.key(:ctrl_c) { |_event, live| live.stop; false }
layout.key(:string) do |event, live|
  if event[:value] == "u"
    sidebar.add_task("Dynamic task #{Time.now.strftime('%H:%M:%S')}", status: :running)
  elsif event[:value] == "q"
    live.stop
  end
  false
end

RubyRich::Live.start(layout, refresh_rate: 20) do |live|
  live.listening = true
end
