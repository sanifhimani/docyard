# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class CalloutChecker < Base
        CALLOUT_TYPES = %w[note tip important warning danger].freeze

        private

        def docs_url
          "https://docyard.dev/write-content/components/callouts/"
        end

        def process_content(content, relative_file)
          blocks = parse_blocks(content)

          filter_blocks(blocks, CALLOUT_TYPES).filter_map do |block|
            validate_callout(block, content, relative_file)
          end
        end

        def validate_callout(block, content, relative_file)
          return build_unclosed_diagnostic("CALLOUT", block, relative_file) unless block[:closed]

          block_content = extract_block_content(content, block[:line])
          return nil unless block_content&.strip&.empty?

          build_diagnostic("CALLOUT_EMPTY", "empty callout block", relative_file, block[:line])
        end
      end
    end
  end
end
