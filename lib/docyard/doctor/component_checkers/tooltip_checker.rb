# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class TooltipChecker < Base
        TOOLTIP_PATTERN = /:tooltip\[([^\]]+)\]\{([^}]*)\}/
        VALID_ATTRS = %w[description link link_text].freeze

        private

        def check_file(file_path)
          relative_file = file_path.delete_prefix("#{docs_path}/")
          content = File.read(file_path)

          each_line_outside_code_blocks(content).flat_map do |line, line_number|
            check_tooltips_in_line(strip_inline_code(line), relative_file, line_number)
          end
        end

        def check_tooltips_in_line(line, relative_file, line_number)
          line.scan(TOOLTIP_PATTERN).flat_map do |_term, attrs_string|
            validate_tooltip_attrs(attrs_string, relative_file, line_number)
          end
        end

        def validate_tooltip_attrs(attrs_string, relative_file, line_number)
          attrs = parse_attrs(attrs_string)
          diagnostics = []

          diagnostics << missing_description_diagnostic(relative_file, line_number) unless attrs.key?("description")
          diagnostics.concat(check_unknown_attrs(attrs.keys, relative_file, line_number))

          diagnostics
        end

        def parse_attrs(attrs_string)
          attrs = {}
          attrs_string.scan(/(\w+)="([^"]*)"/) do |key, value|
            attrs[key] = value
          end
          attrs
        end

        def missing_description_diagnostic(relative_file, line_number)
          build_diagnostic(
            "TOOLTIP_MISSING_DESCRIPTION",
            "tooltip missing required 'description' attribute",
            relative_file,
            line_number
          )
        end

        def check_unknown_attrs(attr_names, relative_file, line_number)
          (attr_names - VALID_ATTRS).map do |attr|
            sug = suggest(attr, VALID_ATTRS)
            msg = "unknown tooltip attribute '#{attr}'"
            msg += ", did you mean '#{sug}'?" if sug
            build_diagnostic("TOOLTIP_UNKNOWN_ATTR", msg, relative_file, line_number)
          end
        end
      end
    end
  end
end
