# frozen_string_literal: true

module Docyard
  class Doctor
    class CodeBlockChecker
      CODE_FENCE_START = /^(`{3,}|~{3,})(\w*)(.*)$/
      CODE_FENCE_END = /^(`{3,}|~{3,})\s*$/
      VALID_OPTIONS = %w[line-numbers no-line-numbers].freeze
      OPTION_PATTERN = /:(\S+)/
      HIGHLIGHT_PATTERN = /\{([^}]+)\}/
      VALID_HIGHLIGHT = /^\d+(-\d+)?(,\s*\d+(-\d+)?)*$/
      INLINE_MARKER_PATTERN = /\[!code\s+([^\]]+)\]/
      VALID_INLINE_MARKERS = %w[++ -- focus error warning].freeze

      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
      end

      def check_file(content, file_path)
        relative_file = file_path.delete_prefix("#{docs_path}/")

        [
          check_fence_options(content, relative_file),
          check_inline_markers(content, relative_file)
        ].flatten
      end

      private

      def check_fence_options(content, relative_file)
        diagnostics = []
        in_code_block = false

        content.each_line.with_index(1) do |line, line_number|
          if !in_code_block && (match = line.match(CODE_FENCE_START))
            in_code_block = true
            diagnostics.concat(validate_fence_line(match, relative_file, line_number))
          elsif in_code_block && line.match?(CODE_FENCE_END)
            in_code_block = false
          end
        end

        diagnostics
      end

      def validate_fence_line(match, relative_file, line_number)
        options_part = match[3]

        [
          validate_option(options_part, relative_file, line_number),
          validate_highlights(options_part, relative_file, line_number)
        ].flatten
      end

      def validate_option(options_part, relative_file, line_number)
        match = options_part.match(OPTION_PATTERN)
        return [] unless match

        option = match[1]
        base_option = option.split("=").first
        return [] if valid_option?(base_option)

        suggestion = suggest(base_option, VALID_OPTIONS)
        message = "unknown code block option ':#{base_option}'"
        message += ", did you mean ':#{suggestion}'?" if suggestion

        [build_diagnostic("CODE_BLOCK_UNKNOWN_OPTION", message, relative_file, line_number)]
      end

      def valid_option?(option)
        VALID_OPTIONS.include?(option) || option.match?(/^line-numbers=\d+$/)
      end

      def validate_highlights(options_part, relative_file, line_number)
        match = options_part.match(HIGHLIGHT_PATTERN)
        return [] unless match

        highlight_content = match[1].gsub(/\s/, "")
        return [] if highlight_content.match?(VALID_HIGHLIGHT)

        [build_diagnostic("CODE_BLOCK_INVALID_HIGHLIGHT", "invalid highlight syntax '{#{match[1]}}'", relative_file,
                          line_number)]
      end

      def check_inline_markers(content, relative_file)
        diagnostics = []
        in_code_block = false

        content.each_line.with_index(1) do |line, line_number|
          if !in_code_block && line.match?(CODE_FENCE_START)
            in_code_block = true
          elsif in_code_block && line.match?(CODE_FENCE_END)
            in_code_block = false
          elsif in_code_block
            diagnostics.concat(validate_inline_markers(line, relative_file, line_number))
          end
        end

        diagnostics
      end

      def validate_inline_markers(line, relative_file, line_number)
        line.scan(INLINE_MARKER_PATTERN).filter_map do |match|
          marker = match[0].strip
          next if VALID_INLINE_MARKERS.include?(marker)

          suggestion = suggest(marker, VALID_INLINE_MARKERS)
          message = "unknown inline marker '[!code #{marker}]'"
          message += ", did you mean '[!code #{suggestion}]'?" if suggestion

          build_diagnostic("CODE_BLOCK_UNKNOWN_MARKER", message, relative_file, line_number)
        end
      end

      def suggest(value, dictionary)
        DidYouMean::SpellChecker.new(dictionary: dictionary).correct(value).first
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
