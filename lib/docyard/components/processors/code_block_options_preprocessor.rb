# frozen_string_literal: true

require_relative "../base_processor"
require_relative "../../rendering/icons"

module Docyard
  module Components
    module Processors
      class CodeBlockOptionsPreprocessor < BaseProcessor
        self.priority = 5

        CODE_FENCE_REGEX = /^```(\w+)(?:\s*\[([^\]]+)\])?(:\S+)?(?:\s*\{([^}\n]+)\})?/
        TABS_BLOCK_REGEX = /^:::tabs[ \t]*\n.*?^:::[ \t]*$/m
        CODE_GROUP_BLOCK_REGEX = /^:::code-group[ \t]*\n.*?^:::[ \t]*$/m
        EXCLUDED_LANGUAGES = %w[filetree].freeze

        def preprocess(content)
          context[:code_block_options] ||= []
          @tabs_ranges = find_tabs_ranges(content)
          @code_group_ranges = find_code_group_ranges(content)

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
          position = match.begin(0)
          return match[0] if inside_special_block?(position)

          original_lang = match[1]
          return match[0] if excluded_language?(original_lang)

          store_code_block_options(match)
          highlight_lang = Icons.highlight_language(original_lang)
          "```#{highlight_lang}"
        end

        def excluded_language?(lang)
          EXCLUDED_LANGUAGES.include?(lang&.downcase)
        end

        def inside_special_block?(position)
          inside_tabs?(position) || inside_code_group?(position)
        end

        def inside_code_group?(position)
          @code_group_ranges.any? { |range| range.cover?(position) }
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
          find_block_ranges(content, TABS_BLOCK_REGEX)
        end

        def find_code_group_ranges(content)
          find_block_ranges(content, CODE_GROUP_BLOCK_REGEX)
        end

        def find_block_ranges(content, regex)
          ranges = []
          content.scan(regex) do
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
