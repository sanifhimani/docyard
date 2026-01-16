# frozen_string_literal: true

module Docyard
  module Components
    module Support
      module MarkdownCodeBlockHelper
        FENCED_CODE_BLOCK_REGEX = /^(`{3,}|~{3,})[^\n]*\n.*?^\1\s*$/m

        def process_outside_code_blocks(content)
          segments = split_by_code_blocks(content)

          segments.map do |segment|
            segment[:type] == :code ? segment[:content] : yield(segment[:content])
          end.join
        end

        def find_code_block_ranges(content, exclude_language: nil)
          ranges = []
          content.scan(FENCED_CODE_BLOCK_REGEX) do
            match = Regexp.last_match
            next if exclude_language && match[0] =~ /\A[`~]{3,}#{exclude_language}\b/

            ranges << (match.begin(0)...match.end(0))
          end
          ranges
        end

        def inside_code_block?(position, ranges)
          ranges.any? { |range| range.cover?(position) }
        end

        private

        def split_by_code_blocks(content)
          segments = []
          current_pos = 0

          content.scan(FENCED_CODE_BLOCK_REGEX) do
            match = Regexp.last_match
            match_start = match.begin(0)
            match_end = match.end(0)

            segments << { type: :text, content: content[current_pos...match_start] } if match_start > current_pos

            segments << { type: :code, content: content[match_start...match_end] }
            current_pos = match_end
          end

          segments << { type: :text, content: content[current_pos..] } if current_pos < content.length

          segments.empty? ? [{ type: :text, content: content }] : segments
        end
      end
    end
  end
end
