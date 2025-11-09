# frozen_string_literal: true

require_relative "icons"

module Docyard
  class IconProcessor
    ICON_PATTERN = /:([a-z][a-z0-9-]*):(?:([a-z]+):)?/i

    def self.process(html)
      segments = split_preserving_code_blocks(html)

      segments.map do |segment|
        segment[:type] == :code ? segment[:content] : process_segment(segment[:content])
      end.join
    end

    def self.split_preserving_code_blocks(html)
      segments = []
      current_pos = 0

      html.scan(%r{<(code|pre)[^>]*>.*?</\1>}m) do
        match_start = Regexp.last_match.begin(0)
        match_end = Regexp.last_match.end(0)

        segments << { type: :text, content: html[current_pos...match_start] } if match_start > current_pos
        segments << { type: :code, content: html[match_start...match_end] }

        current_pos = match_end
      end

      segments << { type: :text, content: html[current_pos..] } if current_pos < html.length

      segments.empty? ? [{ type: :text, content: html }] : segments
    end

    def self.process_segment(content)
      content.gsub(ICON_PATTERN) do
        icon_name = Regexp.last_match(1)
        weight = Regexp.last_match(2) || "regular"
        Icons.render(icon_name, weight) || Regexp.last_match(0)
      end
    end

    private_class_method :split_preserving_code_blocks, :process_segment
  end
end
