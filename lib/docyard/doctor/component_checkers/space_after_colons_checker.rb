# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class SpaceAfterColonsChecker < Base
        SPACE_AFTER_COLONS_PATTERN = /^:::\s+(\w[\w-]*)/

        CALLOUT_TYPES = %w[note tip important warning danger].freeze
        KNOWN_COMPONENTS = %w[tabs cards steps code-group details].freeze
        ALL_CONTAINER_TYPES = (CALLOUT_TYPES + KNOWN_COMPONENTS).freeze

        private

        def check_file(file_path)
          relative_file = file_path.delete_prefix("#{docs_path}/")
          content = File.read(file_path)

          each_line_outside_code_blocks(content).filter_map do |line, line_number|
            next unless (match = line.match(SPACE_AFTER_COLONS_PATTERN))

            component = match[1].downcase
            build_space_diagnostic(component, relative_file, line_number)
          end
        end

        def build_space_diagnostic(component, relative_file, line_number)
          if ALL_CONTAINER_TYPES.include?(component)
            build_diagnostic(
              "COMPONENT_SPACE_AFTER_COLONS",
              "invalid syntax '::: #{component}', did you mean ':::#{component}'?",
              relative_file,
              line_number
            )
          else
            sug = suggest(component, ALL_CONTAINER_TYPES)
            msg = "unknown component '#{component}'"
            msg += ", did you mean ':::#{sug}'?" if sug
            build_diagnostic("COMPONENT_UNKNOWN_TYPE", msg, relative_file, line_number)
          end
        end
      end
    end
  end
end
