# frozen_string_literal: true

module Docyard
  module Components
    module CodeBlockFeatureExtractor
      CODE_FENCE_REGEX = /^```(\w+)(?:\s*\[([^\]]+)\])?(:\S+)?(?:\s*\{([^}\n]+)\})?[ \t]*\n(.*?)^```/m

      DIFF_MARKER_PATTERN = %r{
        (?:
          //\s*\[!code\s*([+-]{2})\]              |
          \#\s*\[!code\s*([+-]{2})\]              |
          /\*\s*\[!code\s*([+-]{2})\]\s*\*/       |
          --\s*\[!code\s*([+-]{2})\]              |
          <!--\s*\[!code\s*([+-]{2})\]\s*-->      |
          ;\s*\[!code\s*([+-]{2})\]
        )[^\S\n]*
      }x

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

      module_function

      def process_markdown(markdown)
        blocks = []
        cleaned = markdown.gsub(CODE_FENCE_REGEX) do
          block_data = extract_block_data(Regexp.last_match)
          blocks << block_data
          "```#{block_data[:lang]}\n#{block_data[:cleaned_content]}```"
        end
        { cleaned_markdown: cleaned, blocks: blocks }
      end

      def extract_block_data(match)
        code_content = match[5]
        diff_info = extract_diff_lines(code_content)
        focus_info = extract_focus_lines(diff_info[:cleaned_content])

        build_block_result(match, diff_info, focus_info)
      end

      def build_block_result(match, diff_info, focus_info)
        {
          lang: match[1],
          title: match[2],
          option: match[3],
          highlights: parse_highlights(match[4]),
          diff_lines: diff_info[:lines],
          focus_lines: focus_info[:lines],
          cleaned_content: focus_info[:cleaned_content]
        }
      end

      def parse_highlights(highlights_str)
        return [] if highlights_str.nil? || highlights_str.strip.empty?

        highlights_str.split(",").flat_map { |part| parse_highlight_part(part.strip) }.uniq.sort
      end

      def parse_highlight_part(part)
        return (part.split("-")[0].to_i..part.split("-")[1].to_i).to_a if part.include?("-")

        [part.to_i]
      end

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
    end
  end
end
