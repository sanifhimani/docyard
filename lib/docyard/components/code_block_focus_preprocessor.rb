# frozen_string_literal: true

require_relative "base_processor"

module Docyard
  module Components
    class CodeBlockFocusPreprocessor < BaseProcessor
      self.priority = 7

      FOCUS_MARKER_PATTERN = %r{
        (?:
          //\s*\[!code\s+focus\]              |
          \#\s*\[!code\s+focus\]              |
          /\*\s*\[!code\s+focus\]\s*\*/       |
          --\s*\[!code\s+focus\]              |
          <!--\s*\[!code\s+focus\]\s*-->      |
          ;\s*\[!code\s+focus\]
        )[^\S\n]*
      }x

      CODE_BLOCK_REGEX = /^```(\w*).*?\n(.*?)^```/m
      TABS_BLOCK_REGEX = /^:::[ \t]*tabs[ \t]*\n.*?^:::[ \t]*$/m

      def preprocess(content)
        context[:code_block_focus_lines] ||= []
        @block_index = 0
        @tabs_ranges = find_tabs_ranges(content)

        content.gsub(CODE_BLOCK_REGEX) { |_| process_code_block(Regexp.last_match) }
      end

      private

      def process_code_block(match)
        return match[0] if inside_tabs?(match.begin(0))

        focus_info = extract_focus_lines(match[2])
        context[:code_block_focus_lines][@block_index] = focus_info[:lines]
        @block_index += 1
        match[0].sub(match[2], focus_info[:cleaned_content])
      end

      def extract_focus_lines(code_content)
        lines = code_content.lines
        focus_lines = {}
        cleaned_lines = []

        lines.each_with_index do |line, index|
          line_num = index + 1

          if line.match?(FOCUS_MARKER_PATTERN)
            focus_lines[line_num] = true
            cleaned_line = line.gsub(FOCUS_MARKER_PATTERN, "")
            cleaned_lines << cleaned_line
          else
            cleaned_lines << line
          end
        end

        { lines: focus_lines, cleaned_content: cleaned_lines.join }
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
    end
  end
end
