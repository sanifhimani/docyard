# frozen_string_literal: true

module Docyard
  class Doctor
    class SidebarFixer
      attr_reader :fixed_issues

      def initialize(docs_path)
        @sidebar_path = File.join(docs_path, "_sidebar.yml")
        @fixed_issues = []
      end

      def fix(issues)
        fixable = issues.select(&:fixable?)
        return if fixable.empty?
        return unless File.exist?(@sidebar_path)

        lines = File.readlines(@sidebar_path)
        fixable.each { |issue| attempt_fix(lines, issue) }
        File.write(@sidebar_path, lines.join)
      end

      def fixed_count
        @fixed_issues.size
      end

      private

      def attempt_fix(lines, issue)
        return unless issue.fix[:type] == :rename

        fix_rename(lines, issue)
      end

      def fix_rename(lines, issue)
        from_key = issue.fix[:from]
        to_key = issue.fix[:to]

        index = lines.find_index { |line| line =~ /^(\s*)#{Regexp.escape(from_key)}:/ }
        return unless index

        lines[index] = lines[index].sub(/#{Regexp.escape(from_key)}:/, "#{to_key}:")
        @fixed_issues << issue
      end
    end
  end
end
