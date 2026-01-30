# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class CodeGroupChecker < Base
        CODE_BLOCK_WITH_LABEL = /^```\w*\s*\[/
        CODE_BLOCK_START = /^```(\w+)/

        private

        def docs_url
          "https://docyard.dev/write-content/components/code-groups/"
        end

        def process_content(content, relative_file)
          blocks = parse_blocks(content)

          filter_blocks(blocks, "code-group").flat_map do |block|
            validate_code_group(block, content, relative_file)
          end.compact
        end

        def validate_code_group(block, content, relative_file)
          return build_unclosed_diagnostic("CODE_GROUP", block, relative_file) unless block[:closed]

          block_content = extract_block_content(content, block[:line])
          unless block_content&.match?(CODE_BLOCK_WITH_LABEL)
            return build_diagnostic("CODE_GROUP_EMPTY", "empty code-group, add code blocks with [labels]",
                                    relative_file, block[:line])
          end

          check_unlabeled_code_blocks(block_content, relative_file, block[:line])
        end

        def check_unlabeled_code_blocks(block_content, relative_file, start_line)
          block_content.each_line.with_index(1).filter_map do |line, offset|
            next unless line.match?(CODE_BLOCK_START) && !line.match?(CODE_BLOCK_WITH_LABEL)

            build_diagnostic("CODE_GROUP_MISSING_LABEL", "code block missing label", relative_file,
                             start_line + offset)
          end
        end
      end
    end
  end
end
