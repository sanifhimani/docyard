# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      # Handles 4+ backtick code fences (extended fences) for showing raw syntax.
      # Escapes special markers so they display as raw text instead of being processed.
      # Example: ```` (4 backticks) wrapping ```js shows the raw markdown syntax.
      class CodeBlockExtendedFencePreprocessor < BaseProcessor
        self.priority = 1

        # Match 4+ backticks, capture language, content, and closing backticks
        EXTENDED_FENCE_REGEX = /^(`{4,})(\w*)[^\n]*\n(.*?)^\1/m

        # Placeholders using zero-width spaces
        BACKTICK_PLACEHOLDER = "\u200B\u200B\u200B"
        CODE_MARKER_PLACEHOLDER = "\u200B!\u200Bcode"

        def preprocess(content)
          content.gsub(EXTENDED_FENCE_REGEX) { |_| process_extended_fence(Regexp.last_match) }
        end

        private

        def process_extended_fence(match)
          lang = match[2]
          code = match[3].chomp

          # Replace backticks and code markers with placeholders
          # This prevents other preprocessors from matching/processing them
          escaped_code = code
            .gsub("`", BACKTICK_PLACEHOLDER)
            .gsub("[!code", CODE_MARKER_PLACEHOLDER)

          # Output as regular 3-backtick fence so it goes through normal processing
          lang_spec = lang.empty? ? "text" : lang
          "```#{lang_spec}\n#{escaped_code}\n```"
        end
      end
    end
  end
end
