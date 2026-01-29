# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class IconChecker < Base
        ICON_PATTERN = /:([a-z][a-z0-9-]*):([a-z]+):/i
        VALID_WEIGHTS = %w[regular bold fill light thin duotone].freeze

        private

        def process_content(content, relative_file)
          each_line_outside_code_blocks(content).flat_map do |line, line_number|
            check_icons_in_line(strip_inline_code(line), relative_file, line_number)
          end
        end

        def check_icons_in_line(line, relative_file, line_number)
          line.scan(ICON_PATTERN).filter_map do |icon_name, weight|
            next if VALID_WEIGHTS.include?(weight.downcase)

            sug = suggest(weight.downcase, VALID_WEIGHTS)
            msg = "unknown icon weight '#{weight}'"
            msg += ", did you mean '#{sug}'?" if sug
            fix = sug ? { type: :line_replace, from: ":#{icon_name}:#{weight}:", to: ":#{icon_name}:#{sug}:" } : nil
            build_diagnostic("ICON_UNKNOWN_WEIGHT", msg, relative_file, line_number, fix: fix)
          end
        end
      end
    end
  end
end
