# frozen_string_literal: true

require_relative "base_processor"

module Docyard
  module Components
    class CodeBlockOptionsPreprocessor < BaseProcessor
      self.priority = 5

      CODE_FENCE_REGEX = /^```(\w+)(:\S+)?/

      def preprocess(content)
        context[:code_block_options] ||= []

        content.gsub(CODE_FENCE_REGEX) do
          lang = Regexp.last_match(1)
          option = Regexp.last_match(2)
          context[:code_block_options] << { lang: lang, option: option }
          "```#{lang}"
        end
      end
    end
  end
end
