# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class DetailsChecker < Base
        DETAILS_ATTR_PATTERN = /^:::details\{([^}]*)\}/
        DETAILS_VALID_ATTRS = %w[title open].freeze

        private

        def check_file(file_path)
          relative_file = file_path.delete_prefix("#{docs_path}/")
          content = File.read(file_path)
          blocks = parse_blocks(content)

          unclosed = filter_blocks(blocks, "details").reject { |b| b[:closed] }.map do |block|
            build_unclosed_diagnostic("DETAILS", block, relative_file)
          end

          unclosed + check_details_attributes(content, relative_file)
        end

        def check_details_attributes(content, relative_file)
          each_line_outside_code_blocks(content).flat_map do |line, line_number|
            next [] unless (match = line.match(DETAILS_ATTR_PATTERN))

            validate_attrs(match[1], relative_file, line_number)
          end
        end

        def validate_attrs(attr_string, relative_file, line_number)
          attrs = extract_attr_names(attr_string) - DETAILS_VALID_ATTRS
          attrs.map do |attr|
            sug = suggest(attr, DETAILS_VALID_ATTRS)
            msg = "unknown details attribute '#{attr}'"
            msg += ", did you mean '#{sug}'?" if sug
            build_diagnostic("DETAILS_UNKNOWN_ATTR", msg, relative_file, line_number)
          end
        end

        def extract_attr_names(attr_string)
          cleaned = attr_string.gsub(/"[^"]*"/, "")
          cleaned.scan(/(\w+)(?:=|\s|$)/).flatten
        end
      end
    end
  end
end
