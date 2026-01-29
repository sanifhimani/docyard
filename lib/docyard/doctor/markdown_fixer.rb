# frozen_string_literal: true

module Docyard
  class Doctor
    class MarkdownFixer
      attr_reader :fixed_issues

      def initialize(docs_path)
        @docs_path = docs_path
        @fixed_issues = []
      end

      def fixed_count
        @fixed_issues.size
      end

      def fix(diagnostics)
        fixable = diagnostics.select(&:fixable?)
        return if fixable.empty?

        fixable.group_by(&:file).each do |file, file_diagnostics|
          fix_file(file, file_diagnostics)
        end
      end

      private

      def fix_file(relative_file, diagnostics)
        file_path = File.join(@docs_path, relative_file)
        return unless File.exist?(file_path)

        lines = File.readlines(file_path)
        apply_all_fixes(lines, diagnostics)
        File.write(file_path, lines.join)
      end

      def apply_all_fixes(lines, diagnostics)
        diagnostics.group_by(&:line).each do |line_number, line_diagnostics|
          next unless valid_line_number?(line_number, lines.size)

          line_diagnostics.each { |d| apply_fix(lines, line_number, d) }
        end
      end

      def valid_line_number?(line_number, total_lines)
        line_number&.positive? && line_number <= total_lines
      end

      def apply_fix(lines, line_number, diagnostic)
        fix = diagnostic.fix
        return unless fix[:type] == :line_replace

        index = line_number - 1
        original_line = lines[index]
        return unless original_line.include?(fix[:from])

        lines[index] = original_line.sub(fix[:from], fix[:to])
        @fixed_issues << diagnostic
      end
    end
  end
end
