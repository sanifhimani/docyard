# frozen_string_literal: true

module Docyard
  class Doctor
    class ComponentChecker
      CALLOUT_TYPES = %w[note tip important warning danger].freeze
      KNOWN_COMPONENTS = %w[tabs cards steps code-group accordion file-tree].freeze
      CONTAINER_PATTERN = /^:::(\w+)/
      CLOSE_PATTERN = /^:::\s*$/
      CODE_FENCE_REGEX = /^(`{3,}|~{3,})/

      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
      end

      def check
        diagnostics = []
        markdown_files.each do |file|
          diagnostics.concat(check_file(file))
        end
        diagnostics
      end

      private

      def markdown_files
        Dir.glob(File.join(docs_path, "**", "*.md"))
      end

      def check_file(file_path)
        relative_file = file_path.delete_prefix("#{docs_path}/")
        content = File.read(file_path)

        check_callouts(content, relative_file)
      end

      def check_callouts(content, relative_file)
        blocks = parse_blocks(content)
        diagnostics = []

        diagnostics.concat(check_empty_callouts(blocks, content, relative_file))
        diagnostics.concat(check_unclosed_callouts(blocks, relative_file))
        diagnostics.concat(check_unknown_types(content, relative_file))

        diagnostics
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

      def check_empty_callouts(blocks, content, relative_file)
        blocks.select { |b| CALLOUT_TYPES.include?(b[:type]) && b[:closed] }.filter_map do |block|
          block_content = extract_block_content(content, block[:line])
          next unless block_content&.strip&.empty?

          build_diagnostic("CALLOUT_EMPTY", "empty callout block", relative_file, block[:line])
        end
      end

      def extract_block_content(content, start_line)
        lines = content.lines
        start_idx = start_line
        end_idx = lines[start_idx..].find_index { |l| l.match?(CLOSE_PATTERN) }
        return nil unless end_idx

        lines[start_idx...(start_idx + end_idx)].join
      end

      def check_unclosed_callouts(blocks, relative_file)
        blocks.select { |b| CALLOUT_TYPES.include?(b[:type]) && !b[:closed] }.map do |block|
          build_diagnostic("CALLOUT_UNCLOSED", "unclosed :::#{block[:type]} block", relative_file, block[:line])
        end
      end

      def check_unknown_types(content, relative_file)
        diagnostics = []
        in_code_block = false

        content.each_line.with_index(1) do |line, line_number|
          in_code_block = !in_code_block if line.match?(CODE_FENCE_REGEX)
          next if in_code_block

          match = line.match(CONTAINER_PATTERN)
          next unless match

          type = match[1].downcase
          next if CALLOUT_TYPES.include?(type) || KNOWN_COMPONENTS.include?(type)

          diagnostics << build_unknown_type_diagnostic(type, relative_file, line_number)
        end

        diagnostics
      end

      def build_unknown_type_diagnostic(type, relative_file, line_number)
        suggestion = DidYouMean::SpellChecker.new(dictionary: CALLOUT_TYPES).correct(type).first
        message = "unknown callout type '#{type}'"
        message += ", did you mean '#{suggestion}'?" if suggestion

        build_diagnostic("CALLOUT_UNKNOWN_TYPE", message, relative_file, line_number)
      end

      def build_diagnostic(code, message, file, line)
        Diagnostic.new(
          severity: :warning,
          category: :COMPONENT,
          code: code,
          message: message,
          file: file,
          line: line
        )
      end
    end
  end
end
