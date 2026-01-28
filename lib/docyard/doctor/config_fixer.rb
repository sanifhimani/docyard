# frozen_string_literal: true

module Docyard
  class Doctor
    class ConfigFixer
      attr_reader :fixed_issues

      def initialize(config_path = "docyard.yml")
        @config_path = config_path
        @fixed_issues = []
      end

      def fix(issues)
        fixable = issues.select(&:fixable?)
        return if fixable.empty?
        return unless File.exist?(@config_path)

        lines = File.readlines(@config_path)
        fixable.each { |issue| attempt_fix(lines, issue) }
        File.write(@config_path, lines.join)
      end

      def fixed_count
        @fixed_issues.size
      end

      private

      def attempt_fix(lines, issue)
        case issue.fix[:type]
        when :replace then fix_replace(lines, issue)
        when :rename then fix_rename(lines, issue)
        end
      end

      def fix_replace(lines, issue)
        key = issue.field.split(".").last
        old_val = normalize_value(issue.got)
        new_val = format_value(issue.fix[:value])

        index = find_line_index(lines, key, old_val)
        return unless index

        lines[index] = lines[index].sub(/:\s*.*$/, ": #{new_val}\n")
        @fixed_issues << issue
      end

      def fix_rename(lines, issue)
        from_key = issue.fix[:from]
        to_key = issue.fix[:to]

        index = lines.find_index { |line| line =~ /^(\s*)#{Regexp.escape(from_key)}:/ }
        return unless index

        lines[index] = lines[index].sub(from_key, to_key)
        @fixed_issues << issue
      end

      def find_line_index(lines, key, old_val)
        lines.find_index do |line|
          line =~ /^(\s*)#{Regexp.escape(key)}:\s*/ && line.include?(old_val.to_s)
        end
      end

      def normalize_value(val)
        return val unless val.is_a?(String)

        val.gsub(/^"|"$/, "")
      end

      def format_value(val)
        case val
        when true then "true"
        when false then "false"
        when String
          val.start_with?("/") ? "\"#{val}\"" : val
        else
          val.to_s
        end
      end
    end
  end
end
