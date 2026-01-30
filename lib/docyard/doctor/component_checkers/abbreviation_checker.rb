# frozen_string_literal: true

module Docyard
  class Doctor
    module ComponentCheckers
      class AbbreviationChecker < Base
        DEFINITION_PATTERN = /^\*\[([^\]]+)\]:\s*(.+)$/

        private

        def docs_url
          "https://docyard.dev/write-content/markdown/#abbreviations"
        end

        def process_content(content, relative_file)
          content_outside_code = content_without_code_blocks(content)

          definitions = extract_definitions(content_outside_code)
          return [] if definitions.empty?

          check_duplicates(definitions, relative_file) +
            check_unused(definitions, content_outside_code, relative_file)
        end

        def content_without_code_blocks(content)
          each_line_outside_code_blocks(content).map { |line, _| line }.join
        end

        def extract_definitions(content)
          definitions = []
          content.each_line.with_index(1) do |line, line_number|
            next unless (match = line.match(DEFINITION_PATTERN))

            definitions << { term: match[1], definition: match[2].strip, line: line_number }
          end
          definitions
        end

        def check_duplicates(definitions, relative_file)
          seen = {}
          definitions.filter_map do |defn|
            if seen.key?(defn[:term])
              build_diagnostic(
                "ABBR_DUPLICATE",
                "abbreviation '#{defn[:term]}' already defined on line #{seen[defn[:term]]}",
                relative_file,
                defn[:line]
              )
            else
              seen[defn[:term]] = defn[:line]
              nil
            end
          end
        end

        def check_unused(definitions, content, relative_file)
          content_without_definitions = content.gsub(DEFINITION_PATTERN, "")

          definitions.filter_map do |defn|
            pattern = /(?<![<\w])#{Regexp.escape(defn[:term])}(?![>\w])/
            next if content_without_definitions.match?(pattern)

            build_diagnostic(
              "ABBR_UNUSED",
              "abbreviation '#{defn[:term]}' defined but never used",
              relative_file,
              defn[:line]
            )
          end
        end
      end
    end
  end
end
