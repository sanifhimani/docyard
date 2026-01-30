# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class CardsChecker < Base
        CARD_ITEM_PATTERN = /^::card\{/
        CARD_ATTR_PATTERN = /^::card\{([^}]*)\}/
        CARD_VALID_ATTRS = %w[title icon href].freeze

        private

        def docs_url
          "https://docyard.dev/write-content/components/cards/"
        end

        def process_content(content, relative_file)
          blocks = parse_blocks(content)

          block_diagnostics = filter_blocks(blocks, "cards").filter_map do |block|
            validate_cards(block, content, relative_file)
          end

          block_diagnostics + check_card_attributes(content, relative_file)
        end

        def validate_cards(block, content, relative_file)
          return build_unclosed_diagnostic("CARDS", block, relative_file) unless block[:closed]

          block_content = extract_block_content(content, block[:line])
          return nil if block_content&.match?(CARD_ITEM_PATTERN)

          build_diagnostic("CARDS_EMPTY", "empty cards block, add '::card{title=\"...\"}' to define cards",
                           relative_file, block[:line])
        end

        def check_card_attributes(content, relative_file)
          each_line_outside_code_blocks(content).flat_map do |line, line_number|
            next [] unless (match = line.match(CARD_ATTR_PATTERN))

            validate_attrs(match[1], relative_file, line_number)
          end
        end

        def validate_attrs(attr_string, relative_file, line_number)
          unknown = attr_string.scan(/(\w+)=/).flatten - CARD_VALID_ATTRS
          unknown.map do |attr|
            sug = suggest(attr, CARD_VALID_ATTRS)
            msg = "unknown card attribute '#{attr}'"
            msg += ", did you mean '#{sug}'?" if sug
            build_diagnostic("CARD_UNKNOWN_ATTR", msg, relative_file, line_number)
          end
        end
      end
    end
  end
end
