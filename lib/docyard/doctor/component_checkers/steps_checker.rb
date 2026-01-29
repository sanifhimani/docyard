# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class StepsChecker < Base
        STEP_ITEM_PATTERN = /^###\s+.+/

        private

        def check_file(file_path)
          relative_file = file_path.delete_prefix("#{docs_path}/")
          content = File.read(file_path)
          blocks = parse_blocks(content)

          filter_blocks(blocks, "steps").filter_map do |block|
            validate_steps(block, content, relative_file)
          end
        end

        def validate_steps(block, content, relative_file)
          return build_unclosed_diagnostic("STEPS", block, relative_file) unless block[:closed]

          block_content = extract_block_content(content, block[:line])
          return nil if block_content&.match?(STEP_ITEM_PATTERN)

          build_diagnostic("STEPS_EMPTY", "empty steps block, add '### Step Title' to define steps", relative_file,
                           block[:line])
        end
      end
    end
  end
end
