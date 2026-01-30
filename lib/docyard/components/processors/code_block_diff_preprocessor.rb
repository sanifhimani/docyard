# frozen_string_literal: true

require_relative "../base_processor"
require_relative "../support/code_block/patterns"

module Docyard
  module Components
    module Processors
      class CodeBlockDiffPreprocessor < BaseProcessor
        include Support::CodeBlock::Patterns

        self.priority = 6

        CODE_BLOCK_REGEX = /^```(\w*).*?\n(.*?)^```/m
        TABS_BLOCK_REGEX = /^:::tabs[ \t]*\n.*?^:::[ \t]*$/m

        def preprocess(content)
          context[:code_block_diff_lines] ||= []
          context[:code_block_error_lines] ||= []
          context[:code_block_warning_lines] ||= []
          @block_index = 0
          @tabs_ranges = find_tabs_ranges(content)

          content.gsub(CODE_BLOCK_REGEX) { |_| process_code_block(Regexp.last_match) }
        end

        private

        def process_code_block(match)
          return match[0] if inside_tabs?(match.begin(0))

          result = extract_all_markers(match[2])
          store_extracted_markers(result)
          @block_index += 1
          match[0].sub(match[2], result[:cleaned_content])
        end

        def store_extracted_markers(result)
          context[:code_block_diff_lines][@block_index] = result[:diff_lines]
          context[:code_block_error_lines][@block_index] = result[:error_lines]
          context[:code_block_warning_lines][@block_index] = result[:warning_lines]
        end

        def extract_all_markers(code_content)
          diff_info = extract_diff_lines(code_content)
          error_info = extract_error_lines(diff_info[:cleaned_content])
          warning_info = extract_warning_lines(error_info[:cleaned_content])

          {
            diff_lines: diff_info[:lines],
            error_lines: error_info[:lines],
            warning_lines: warning_info[:lines],
            cleaned_content: warning_info[:cleaned_content]
          }
        end

        def extract_diff_lines(code_content)
          extract_marker_lines(code_content, DIFF_MARKER_PATTERN) do |match|
            diff_type = match.captures.compact.first
            diff_type == "++" ? :addition : :deletion
          end
        end

        def extract_error_lines(code_content)
          extract_marker_lines(code_content, ERROR_MARKER_PATTERN) { true }
        end

        def extract_warning_lines(code_content)
          extract_marker_lines(code_content, WARNING_MARKER_PATTERN) { true }
        end

        def extract_marker_lines(code_content, pattern)
          lines = code_content.lines
          marker_lines = {}
          cleaned_lines = []

          lines.each_with_index do |line, index|
            line_num = index + 1

            if (match = line.match(pattern))
              marker_lines[line_num] = yield(match)
              cleaned_lines << line.gsub(pattern, "")
            else
              cleaned_lines << line
            end
          end

          { lines: marker_lines, cleaned_content: cleaned_lines.join }
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
end
