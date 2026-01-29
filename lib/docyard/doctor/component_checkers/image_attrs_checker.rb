# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class ImageAttrsChecker < Base
        IMAGE_ATTRS_PATTERN = /!\[[^\]]*\]\([^)]+\)\{([^}]+)\}/
        VALID_ATTRS = %w[caption width height nozoom].freeze

        private

        def check_file(file_path)
          relative_file = file_path.delete_prefix("#{docs_path}/")
          content = File.read(file_path)

          each_line_outside_code_blocks(content).flat_map do |line, line_number|
            check_images_in_line(strip_inline_code(line), relative_file, line_number)
          end
        end

        def check_images_in_line(line, relative_file, line_number)
          line.scan(IMAGE_ATTRS_PATTERN).flat_map do |attrs_string,|
            check_unknown_attrs(attrs_string, relative_file, line_number)
          end
        end

        def check_unknown_attrs(attrs_string, relative_file, line_number)
          attrs = extract_attr_names(attrs_string)
          (attrs - VALID_ATTRS).map do |attr|
            sug = suggest(attr, VALID_ATTRS)
            msg = "unknown image attribute '#{attr}'"
            msg += ", did you mean '#{sug}'?" if sug
            fix = sug ? { type: :line_replace, from: "#{attr}=", to: "#{sug}=" } : nil
            build_diagnostic("IMAGE_UNKNOWN_ATTR", msg, relative_file, line_number, fix: fix)
          end
        end

        def extract_attr_names(attrs_string)
          cleaned = attrs_string.gsub(/"[^"]*"/, "")
          cleaned.scan(/(\w+)(?:=|\s|$)/).flatten
        end
      end
    end
  end
end
