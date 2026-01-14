# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      class BadgeProcessor < BaseProcessor
        self.priority = 15

        BADGE_PATTERN = /:badge\[([^\]]*)\](?:\{([^}]*)\})?/

        VALID_TYPES = %w[default success warning danger].freeze

        def postprocess(html)
          segments = split_preserving_code_blocks(html)

          segments.map do |segment|
            segment[:type] == :code ? segment[:content] : process_segment(segment[:content])
          end.join
        end

        private

        def split_preserving_code_blocks(html)
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

        def process_segment(content)
          content.gsub(BADGE_PATTERN) do
            text = Regexp.last_match(1)
            attrs = Regexp.last_match(2)

            render_badge(text, parse_attributes(attrs))
          end
        end

        def parse_attributes(attrs_string)
          return {} if attrs_string.nil? || attrs_string.empty?

          attrs = {}
          attrs_string.scan(/(\w+)=["'\u201C\u201D]([^"'\u201C\u201D]*)["'\u201C\u201D]/) do |key, value|
            attrs[key] = value
          end
          attrs
        end

        def render_badge(text, attrs)
          type = attrs["type"] || "default"
          type = "default" unless VALID_TYPES.include?(type)

          %(<span class="docyard-badge docyard-badge--#{type}">#{text}</span>)
        end
      end
    end
  end
end
