# frozen_string_literal: true

module Docyard
  module DiagnosticContext
    CONTEXT_LINES = 2

    class << self
      def find_yaml_key_line(file_path, key_path)
        return nil unless File.exist?(file_path)

        lines = File.readlines(file_path)
        target_key = key_path.to_s.split(".").last

        lines.each_with_index do |line, index|
          next if line.strip.empty? || line.strip.start_with?("#")

          return index + 1 if line_contains_key?(line, target_key)
        end

        nil
      end

      def extract_source_context(file_path, line_number, context_lines: CONTEXT_LINES)
        return nil unless file_path && line_number && File.exist?(file_path)

        lines = File.readlines(file_path)
        return nil if line_number < 1 || line_number > lines.length

        start_line = [line_number - context_lines, 1].max
        end_line = [line_number + context_lines, lines.length].min

        (start_line..end_line).map do |num|
          {
            line: num,
            content: lines[num - 1].chomp,
            highlighted: num == line_number
          }
        end
      end

      private

      def line_contains_key?(line, key)
        line.match?(/^\s*#{Regexp.escape(key)}:/) || line.match?(/^\s*-\s*#{Regexp.escape(key)}:?(\s|$)/)
      end
    end
  end
end
