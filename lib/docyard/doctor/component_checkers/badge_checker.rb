# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class BadgeChecker < Base
        BADGE_PATTERN = /:badge\[([^\]]*)\](?:\{([^}]*)\})?/
        VALID_TYPES = %w[default success warning danger].freeze
        VALID_ATTRS = %w[type].freeze

        private

        def docs_url
          "https://docyard.dev/write-content/components/badges/"
        end

        def process_content(content, relative_file)
          each_line_outside_code_blocks(content).flat_map do |line, line_number|
            check_badges_in_line(strip_inline_code(line), relative_file, line_number)
          end
        end

        def check_badges_in_line(line, relative_file, line_number)
          line.scan(BADGE_PATTERN).flat_map do |_text, attrs_string|
            next [] if attrs_string.nil? || attrs_string.empty?

            validate_badge_attrs(attrs_string, relative_file, line_number)
          end
        end

        def validate_badge_attrs(attrs_string, relative_file, line_number)
          attrs = parse_attrs(attrs_string)
          diagnostics = []

          diagnostics.concat(check_unknown_attrs(attrs, relative_file, line_number))
          diagnostics.concat(check_unknown_type(attrs["type"], relative_file, line_number)) if attrs.key?("type")

          diagnostics
        end

        def parse_attrs(attrs_string)
          attrs = {}
          attrs_string.scan(/(\w+)=["']([^"']*)["']/) do |key, value|
            attrs[key] = value
          end
          attrs
        end

        def check_unknown_attrs(attrs, relative_file, line_number)
          (attrs.keys - VALID_ATTRS).map do |attr|
            sug = suggest(attr, VALID_ATTRS)
            msg = "unknown badge attribute '#{attr}'"
            msg += ", did you mean '#{sug}'?" if sug
            fix = sug ? { type: :line_replace, from: "#{attr}=", to: "#{sug}=" } : nil
            build_diagnostic("BADGE_UNKNOWN_ATTR", msg, relative_file, line_number, fix: fix)
          end
        end

        def check_unknown_type(type_value, relative_file, line_number)
          return [] if VALID_TYPES.include?(type_value)

          sug = suggest(type_value, VALID_TYPES)
          msg = "unknown badge type '#{type_value}'"
          msg += ", did you mean '#{sug}'?" if sug
          fix = sug ? { type: :line_replace, from: "type=\"#{type_value}\"", to: "type=\"#{sug}\"" } : nil
          [build_diagnostic("BADGE_UNKNOWN_TYPE", msg, relative_file, line_number, fix: fix)]
        end
      end
    end
  end
end
