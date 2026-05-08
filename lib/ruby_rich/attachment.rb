# frozen_string_literal: true

module RubyRich
  class Attachment
    attr_accessor :type, :path, :mime_type, :display_name, :metadata

    def initialize(type:, path:, mime_type: nil, display_name: nil, metadata: {})
      @type = type.to_sym
      @path = path.to_s
      @mime_type = mime_type
      @display_name = display_name || File.basename(@path)
      @metadata = metadata.dup
    end

    def to_h
      {
        type: @type,
        path: @path,
        mime_type: @mime_type,
        display_name: @display_name,
        metadata: @metadata
      }.compact
    end
  end
end
