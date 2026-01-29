# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class TabsChecker < Base
        TAB_ITEM_PATTERN = /^==\s+.+/

        private

        def check_file(file_path)
          relative_file = file_path.delete_prefix("#{docs_path}/")
          content = File.read(file_path)
          blocks = parse_blocks(content)

          filter_blocks(blocks, "tabs").filter_map do |block|
            validate_tabs(block, content, relative_file)
          end
        end

        def validate_tabs(block, content, relative_file)
          return build_unclosed_diagnostic("TABS", block, relative_file) unless block[:closed]

          block_content = extract_block_content(content, block[:line])
          return nil if block_content&.match?(TAB_ITEM_PATTERN)

          build_diagnostic("TABS_EMPTY", "empty tabs block, add '== Tab Name' to define tabs", relative_file,
                           block[:line])
        end
      end
    end
  end
end
