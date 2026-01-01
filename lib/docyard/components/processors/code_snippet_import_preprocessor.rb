# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      class CodeSnippetImportPreprocessor < BaseProcessor
        EXTENSION_MAP = {
          "rb" => "ruby",
          "js" => "javascript",
          "ts" => "typescript",
          "py" => "python",
          "yml" => "yaml",
          "md" => "markdown",
          "sh" => "bash",
          "zsh" => "bash",
          "jsx" => "jsx",
          "tsx" => "tsx"
        }.freeze

        IMPORT_PATTERN = %r{^<<<\s+@/([^\s{#]+)(?:#([\w-]+))?(?:\{([^}]+)\})?\s*$}

        self.priority = 1

        def preprocess(content)
          @docs_root = context[:docs_root] || "docs"
          content.gsub(IMPORT_PATTERN) { |_| process_import(Regexp.last_match) }
        end

        private

        def process_import(match)
          filepath = match[1]
          region = match[2]
          options = match[3]

          file_content = read_file(filepath)
          return import_error(filepath, "File not found") unless file_content

          file_content = extract_region(file_content, region) if region
          return import_error(filepath, "Region '#{region}' not found") unless file_content

          build_code_block(file_content, filepath, options)
        end

        def read_file(filepath)
          full_path = File.join(@docs_root, filepath)
          return nil unless File.exist?(full_path)

          File.read(full_path)
        end

        def extract_region(content, region_name)
          region_start = %r{^[ \t]*(?://|#|/\*)\s*#region\s+#{Regexp.escape(region_name)}\b.*$}
          region_end = %r{^[ \t]*(?://|#|/\*|\*/)\s*#endregion\s*#{Regexp.escape(region_name)}?\b.*$}

          lines = content.lines
          start_index = lines.find_index { |line| line.match?(region_start) }
          return nil unless start_index

          end_index = lines[(start_index + 1)..].find_index { |line| line.match?(region_end) }
          return nil unless end_index

          end_index += start_index + 1
          lines[(start_index + 1)...end_index].join
        end

        def build_code_block(content, filepath, options)
          lang = detect_language(filepath)
          highlights = nil

          if options
            parsed = parse_options(options)
            lang = parsed[:lang] if parsed[:lang]
            highlights = parsed[:highlights] if parsed[:highlights]
          end

          content = extract_line_range(content, highlights) if highlights&.include?("-") && !highlights.include?(",")

          meta = build_meta_string(highlights, filepath)

          "```#{lang}#{meta}\n#{content.chomp}\n```"
        end

        def parse_options(options)
          parts = options.strip.split(/\s+/)
          result = { highlights: nil, lang: nil }

          parts.each do |part|
            if part.match?(/^[\d,-]+$/)
              result[:highlights] = part
            else
              result[:lang] = part
            end
          end

          result
        end

        def extract_line_range(content, range_str)
          return content unless range_str&.match?(/^\d+-\d+$/)

          start_line, end_line = range_str.split("-").map(&:to_i)
          lines = content.lines
          lines[(start_line - 1)..(end_line - 1)]&.join || content
        end

        def build_meta_string(highlights, filepath)
          parts = []
          parts << " [#{File.basename(filepath)}]" if filepath
          parts << " {#{highlights}}" if highlights && !highlights.match?(/^\d+-\d+$/)
          parts.join
        end

        def detect_language(filepath)
          ext = File.extname(filepath).delete_prefix(".")
          EXTENSION_MAP[ext] || ext
        end

        def import_error(filepath, message)
          "```\nError importing #{filepath}: #{message}\n```"
        end
      end
    end
  end
end
