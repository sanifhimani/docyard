# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class UnknownTypeChecker < Base
        CALLOUT_TYPES = %w[note tip important warning danger].freeze
        KNOWN_COMPONENTS = %w[tabs cards steps code-group details].freeze
        ALL_CONTAINER_TYPES = (CALLOUT_TYPES + KNOWN_COMPONENTS).freeze

        private

        def check_file(file_path)
          relative_file = file_path.delete_prefix("#{docs_path}/")
          content = File.read(file_path)

          each_line_outside_code_blocks(content).filter_map do |line, line_number|
            next unless (m = line.match(CONTAINER_PATTERN))

            type = m[1].downcase
            next if ALL_CONTAINER_TYPES.include?(type)

            sug = suggest(type, ALL_CONTAINER_TYPES)
            msg = "unknown component ':::#{type}'"
            msg += ", did you mean ':::#{sug}'?" if sug
            build_diagnostic("COMPONENT_UNKNOWN_TYPE", msg, relative_file, line_number)
          end
        end
      end
    end
  end
end
