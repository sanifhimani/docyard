# frozen_string_literal: true

module Docyard
  class Doctor
    class Reporter
      attr_reader :results, :stats, :fixed

      def initialize(results, stats = {}, fixed: false)
        @results = results
        @stats = stats
        @fixed = fixed
      end

      def print
        puts
        puts "  #{UI.bold('Docyard')} v#{VERSION}"
        puts
        puts "  Checking docs..."
        puts
        print_config_issues
        print_broken_links
        print_missing_images
        print_orphan_pages
        print_summary
      end

      def exit_code
        error_count.positive? ? 1 : 0
      end

      private

      def print_config_issues
        issues = results[:config_issues]
        return if issues.empty?

        errors = issues.select(&:error?)
        warnings = issues.select(&:warning?)

        puts "  #{UI.bold('Configuration')}        #{issue_counts(errors.size, warnings.size)}"
        issues.each do |issue|
          puts "    #{issue.format_short}"
        end
        puts
      end

      def print_broken_links
        issues = results[:broken_links]
        return if issues.empty?

        puts "  #{UI.bold('Broken links')}         #{UI.red(pluralize(issues.size, 'error'))}"
        issues.each do |issue|
          location = "#{issue.file}:#{issue.line}"
          puts "    #{UI.dim(location.ljust(24))} #{issue.target}"
        end
        puts
      end

      def print_missing_images
        issues = results[:missing_images]
        return if issues.empty?

        puts "  #{UI.bold('Missing images')}       #{UI.red(pluralize(issues.size, 'error'))}"
        issues.each do |issue|
          location = "#{issue.file}:#{issue.line}"
          puts "    #{UI.dim(location.ljust(24))} #{issue.target}"
        end
        puts
      end

      def print_orphan_pages
        orphans = results[:orphan_pages]
        return if orphans.empty?

        puts "  #{UI.bold('Orphan pages')}         #{UI.yellow(pluralize(orphans.size, 'warning'))}"
        orphans.each do |orphan|
          puts "    #{orphan[:file]}"
        end
        puts
      end

      def print_summary
        puts "  #{stats_summary}"

        if error_count.zero? && warning_count.zero?
          puts "  #{UI.success('No issues found')}"
        else
          puts "  #{build_issue_summary}"
          print_fixable_hint
        end
        puts
      end

      def print_fixable_hint
        return if fixed

        fixable = results[:config_issues].count(&:fixable?)
        return if fixable.zero?

        puts
        puts "  #{UI.cyan("Run with --fix to auto-fix #{pluralize(fixable, 'issue')}.")}"
      end

      def issue_counts(error_count, warning_count)
        parts = []
        parts << UI.red(pluralize(error_count, "error")) if error_count.positive?
        parts << UI.yellow(pluralize(warning_count, "warning")) if warning_count.positive?
        parts.join(", ")
      end

      def stats_summary
        stats_parts = [
          stat_part(:files, "file"),
          stat_part(:links, "link"),
          stat_part(:images, "image")
        ].compact
        "Checked #{stats_parts.join(', ')}"
      end

      def stat_part(key, word)
        pluralize(stats[key], word) if stats[key]
      end

      def build_issue_summary
        parts = []
        parts << UI.red(pluralize(error_count, "error")) if error_count.positive?
        parts << UI.yellow(pluralize(warning_count, "warning")) if warning_count.positive?
        "Found #{parts.join(', ')}"
      end

      def pluralize(count, word)
        count == 1 ? "#{count} #{word}" : "#{count} #{word}s"
      end

      def error_count
        config_errors = results[:config_issues].count(&:error?)
        config_errors + results[:broken_links].size + results[:missing_images].size
      end

      def warning_count
        config_warnings = results[:config_issues].count(&:warning?)
        config_warnings + results[:orphan_pages].size
      end
    end
  end
end
