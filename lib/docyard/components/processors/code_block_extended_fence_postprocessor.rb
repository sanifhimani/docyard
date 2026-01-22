# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      # Restores placeholders after all code block processing.
      # Runs after CodeBlockProcessor to ensure the HTML is fully rendered.
      class CodeBlockExtendedFencePostprocessor < BaseProcessor
        self.priority = 25

        BACKTICK_PLACEHOLDER = "\u200B\u200B\u200B"
        CODE_MARKER_PLACEHOLDER = "\u200B!\u200Bcode"

        def postprocess(html)
          html
            .gsub(BACKTICK_PLACEHOLDER, "`")
            .gsub(CODE_MARKER_PLACEHOLDER, "[!code")
        end
      end
    end
  end
end
