# frozen_string_literal: true

module Docyard
  module Components
    module Support
      module CodeBlock
        module LineNumberResolver
          module_function

          def enabled?(option, global_default: false)
            return false if option == ":no-line-numbers"
            return true if option&.start_with?(":line-numbers")

            global_default
          end

          def start_line(option)
            return 1 unless option&.include?("=")

            option.split("=").last.to_i
          end

          def generate_numbers(code_text, start = 1)
            line_count = [code_text.lines.count, 1].max
            (start...(start + line_count)).to_a
          end
        end
      end
    end
  end
end
