#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ruby_rich'

layout = RubyRich::Layout.new(name: :root)
layout.split_column(
  RubyRich::Layout.new(name: :main, ratio: 1),
  RubyRich::Layout.new(name: :composer, size: 6)
)
layout[:main].split_row(
  RubyRich::Layout.new(name: :transcript, ratio: 1),
  RubyRich::Layout.new(name: :sidebar, size: 42)
)
layout[:sidebar].split_column(
  RubyRich::Layout.new(name: :plan, ratio: 1),
  RubyRich::Layout.new(name: :tasks, ratio: 1)
)

class FocusPanel
  attr_accessor :width, :height

  def initialize(title, content)
    @title = title
    @content = content
    @focused = false
    @width = 0
    @height = 0
  end

  def focus
    @focused = true
    self
  end

  def blur
    @focused = false
    self
  end

  def render
    panel = RubyRich::Panel.new(@content, title: @title, border_style: @focused ? :green : :blue, title_align: :left)
    panel.width = @width
    panel.height = @height
    panel.render
  end
end

focus = RubyRich::FocusManager.new
transcript = RubyRich::Viewport.new(["Transcript focus target", "Click here or press Tab."], scrollbar: true)
plan = FocusPanel.new("Plan", "tracks focus demo")
tasks = FocusPanel.new("Tasks", "● Click panels\n○ Press Tab to cycle")
composer = RubyRich::Composer.new(placeholder: "Focus demo input")

layout[:transcript].content = transcript
layout[:plan].content = plan
layout[:tasks].content = tasks
layout[:composer].content = composer

focus.register(:transcript, layout[:transcript], transcript)
focus.register(:plan, layout[:plan], plan)
focus.register(:tasks, layout[:tasks], tasks)
focus.register(:composer, layout[:composer], composer)
focus.attach(layout)

layout.key(:ctrl_c) { |_event, live| live.stop; false }
layout.key(:string) { |event, live| live.stop if event[:value] == "q"; false }

RubyRich::Live.start(layout, refresh_rate: 20, mouse: true) do |live|
  live.listening = true
end
