# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      class CodeBlockOptionsPreprocessor < BaseProcessor
        self.priority = 5

        CODE_FENCE_REGEX = /^```(\w+)(?:\s*\[([^\]]+)\])?(:\S+)?(?:\s*\{([^}\n]+)\})?/
        TABS_BLOCK_REGEX = /^:::[ \t]*tabs[ \t]*\n.*?^:::[ \t]*$/m

        def preprocess(content)
          context[:code_block_options] ||= []
          @tabs_ranges = find_tabs_ranges(content)

          process_code_fences(content)
        end

        private

        def process_code_fences(content)
          result = +""
          last_end = 0

          content.scan(CODE_FENCE_REGEX) do
            match = Regexp.last_match
            result << content[last_end...match.begin(0)]
            result << process_fence_match(match)
            last_end = match.end(0)
          end

          result << content[last_end..]
        end

        def process_fence_match(match)
          store_code_block_options(match) unless inside_tabs?(match.begin(0))
          "```#{match[1]}"
        end

        def store_code_block_options(match)
          context[:code_block_options] << {
            lang: match[1],
            title: match[2],
            option: match[3],
            highlights: parse_highlights(match[4])
          }
        end

        def inside_tabs?(position)
          @tabs_ranges.any? { |range| range.cover?(position) }
        end

        def find_tabs_ranges(content)
          ranges = []
          content.scan(TABS_BLOCK_REGEX) do
            match = Regexp.last_match
            ranges << (match.begin(0)...match.end(0))
          end
          ranges
        end

        def parse_highlights(highlights_str)
          return [] if highlights_str.nil? || highlights_str.strip.empty?

          highlights_str.split(",").flat_map { |part| parse_highlight_part(part.strip) }.uniq.sort
        end

        def parse_highlight_part(part)
          return (part.split("-")[0].to_i..part.split("-")[1].to_i).to_a if part.include?("-")

          [part.to_i]
        end
      end
    end
  end
end
