# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class UnknownTypeChecker < Base
        CALLOUT_TYPES = %w[note tip important warning danger].freeze
        KNOWN_COMPONENTS = %w[tabs cards steps code-group details].freeze
        ALL_CONTAINER_TYPES = (CALLOUT_TYPES + KNOWN_COMPONENTS).freeze

        private

        def process_content(content, relative_file)
          each_line_outside_code_blocks(content).filter_map do |line, line_number|
            next unless (m = line.match(CONTAINER_PATTERN))

            type = m[1].downcase
            next if ALL_CONTAINER_TYPES.include?(type)

            build_unknown_type_diagnostic(type, m[1], relative_file, line_number)
          end
        end

        def build_unknown_type_diagnostic(type, original_type, relative_file, line_number)
          sug = suggest(type, ALL_CONTAINER_TYPES)
          msg = "unknown component ':::#{type}'"
          msg += ", did you mean ':::#{sug}'?" if sug
          fix = sug ? { type: :line_replace, from: ":::#{original_type}", to: ":::#{sug}" } : nil
          build_diagnostic("COMPONENT_UNKNOWN_TYPE", msg, relative_file, line_number, fix: fix)
        end
      end
    end
  end
end
