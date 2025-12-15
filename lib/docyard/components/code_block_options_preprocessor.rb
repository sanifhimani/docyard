# frozen_string_literal: true

require_relative "base_processor"

module Docyard
  module Components
    class CodeBlockOptionsPreprocessor < BaseProcessor
      self.priority = 5

      CODE_FENCE_REGEX = /^```(\w+)(:\S+)?(?:\s*\{([^}]+)\})?/

      def preprocess(content)
        context[:code_block_options] ||= []

        content.gsub(CODE_FENCE_REGEX) do
          lang = Regexp.last_match(1)
          option = Regexp.last_match(2)
          highlights_str = Regexp.last_match(3)
          highlights = parse_highlights(highlights_str)
          context[:code_block_options] << { lang: lang, option: option, highlights: highlights }
          "```#{lang}"
        end
      end

      private

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
