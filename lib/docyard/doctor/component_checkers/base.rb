# frozen_string_literal: true

require_relative "../../diagnostic_context"

module Docyard
  class Doctor
    module ComponentCheckers
      class Base
        CONTAINER_PATTERN = /^:::(\w[\w-]*)/
        CLOSE_PATTERN = /^:::\s*$/
        CODE_FENCE_REGEX = /^(`{3,}|~{3,})/

        COMPONENTS_DOCS_URL = "https://docyard.dev/write-content/components/"

        attr_reader :docs_path

        def initialize(docs_path)
          @docs_path = docs_path
        end

        def check_file(content, file_path)
          @current_file_path = file_path
          relative_file = file_path.delete_prefix("#{docs_path}/")
          process_content(content, relative_file)
        end

        private

        def process_content(_content, _relative_file)
          raise NotImplementedError
        end

        def parse_blocks(content)
          blocks = []
          open_blocks = []
          in_code_block = false

          content.each_line.with_index(1) do |line, line_number|
            in_code_block = !in_code_block if line.match?(CODE_FENCE_REGEX)
            next if in_code_block

            process_block_line(line, line_number, open_blocks, blocks)
          end

          open_blocks.each { |b| b[:closed] = false }
          blocks + open_blocks
        end

        def process_block_line(line, line_number, open_blocks, blocks)
          if (match = line.match(CONTAINER_PATTERN))
            open_blocks.push({ type: match[1].downcase, line: line_number, closed: true })
          elsif line.match?(CLOSE_PATTERN) && open_blocks.any?
            blocks.push(open_blocks.pop)
          end
        end

        def extract_block_content(content, start_line)
          lines = content.lines
          end_idx = lines[start_line..].find_index { |l| l.match?(CLOSE_PATTERN) }
          end_idx ? lines[start_line...(start_line + end_idx)].join : nil
        end

        def each_line_outside_code_blocks(content)
          return enum_for(__method__, content) unless block_given?

          in_code_block = false
          content.each_line.with_index(1) do |line, line_number|
            in_code_block = !in_code_block if line.match?(CODE_FENCE_REGEX)
            yield line, line_number unless in_code_block
          end
        end

        def filter_blocks(blocks, type_filter)
          blocks.select { |b| type_filter.is_a?(Array) ? type_filter.include?(b[:type]) : b[:type] == type_filter }
        end

        def suggest(value, dictionary)
          DidYouMean::SpellChecker.new(dictionary: dictionary).correct(value).first
        end

        def strip_inline_code(line)
          line.gsub(/`[^`]+`/, "")
        end

        def build_unclosed_diagnostic(prefix, block, relative_file)
          build_diagnostic("#{prefix}_UNCLOSED", "unclosed :::#{block[:type]} block", relative_file, block[:line])
        end

        def build_diagnostic(code, message, file, line, fix: nil)
          source_context = DiagnosticContext.extract_source_context(@current_file_path, line)

          Diagnostic.new(
            severity: :warning,
            category: :COMPONENT,
            code: code,
            message: message,
            file: file,
            line: line,
            fix: fix,
            doc_url: docs_url,
            source_context: source_context
          )
        end

        def docs_url
          COMPONENTS_DOCS_URL
        end
      end
    end
  end
end
