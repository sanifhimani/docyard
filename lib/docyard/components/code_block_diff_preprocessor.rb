# frozen_string_literal: true

require_relative "base_processor"

module Docyard
  module Components
    class CodeBlockDiffPreprocessor < BaseProcessor
      self.priority = 6 # After CodeBlockOptionsPreprocessor (5)

      DIFF_MARKER_PATTERN = %r{
        (?:
          //\s*\[!code\s*([+-]{2})\]              |  # // [!code ++]
          \#\s*\[!code\s*([+-]{2})\]                |  # \# [!code ++]
          /\*\s*\[!code\s*([+-]{2})\]\s*\*/      |  # /* [!code ++] */
          --\s*\[!code\s*([+-]{2})\]                |  # -- [!code ++]
          <!--\s*\[!code\s*([+-]{2})\]\s*-->       |  # <!-- [!code ++] -->
          ;\s*\[!code\s*([+-]{2})\]                    # ; [!code ++]
        )[^\S\n]*$
      }x

      CODE_BLOCK_REGEX = /^```(\w*).*?\n(.*?)^```/m

      def preprocess(content)
        context[:code_block_diff_lines] ||= []
        @block_index = 0

        content.gsub(CODE_BLOCK_REGEX) do
          full_match = Regexp.last_match(0)
          code_content = Regexp.last_match(2)

          diff_info = extract_diff_lines(code_content)
          context[:code_block_diff_lines][@block_index] = diff_info[:lines]

          cleaned_code = diff_info[:cleaned_content]
          @block_index += 1

          full_match.sub(code_content, cleaned_code)
        end
      end

      private

      def extract_diff_lines(code_content)
        lines = code_content.lines
        diff_lines = {}
        cleaned_lines = []

        lines.each_with_index do |line, index|
          line_num = index + 1

          if (match = line.match(DIFF_MARKER_PATTERN))
            diff_type = match.captures.compact.first
            diff_lines[line_num] = diff_type == "++" ? :addition : :deletion

            cleaned_line = line.gsub(DIFF_MARKER_PATTERN, "")
            cleaned_lines << cleaned_line
          else
            cleaned_lines << line
          end
        end

        { lines: diff_lines, cleaned_content: cleaned_lines.join }
      end
    end
  end
end
