# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      class IconProcessor < BaseProcessor
        self.priority = 20

        ICON_PATTERN = /:([a-z][a-z0-9-]*):(?:([a-z]+):)?/i
        VALID_WEIGHTS = %w[regular bold fill light thin duotone].freeze

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
          content.gsub(ICON_PATTERN) do
            icon_name = Regexp.last_match(1)
            weight = Regexp.last_match(2) || "regular"
            render_icon(icon_name, weight)
          end
        end

        def render_icon(name, weight)
          weight = "regular" unless VALID_WEIGHTS.include?(weight)
          weight_class = weight == "regular" ? "ph" : "ph-#{weight}"
          %(<i class="#{weight_class} ph-#{name}" aria-hidden="true"></i>)
        end
      end
    end
  end
end
