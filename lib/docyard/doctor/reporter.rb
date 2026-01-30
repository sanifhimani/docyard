# frozen_string_literal: true

module Docyard
  class Doctor
    class Reporter
      CATEGORY_LABELS = {
        CONFIG: "Configuration",
        SIDEBAR: "Sidebar",
        CONTENT: "Content",
        COMPONENT: "Components",
        SYNTAX: "Syntax",
        LINK: "Broken links",
        IMAGE: "Missing images",
        ORPHAN: "Orphan pages"
      }.freeze

      CATEGORY_ORDER = %i[CONFIG SIDEBAR CONTENT COMPONENT LINK IMAGE ORPHAN SYNTAX].freeze

      attr_reader :diagnostics, :stats, :fixed, :duration

      def initialize(diagnostics, stats = {}, fixed: false, duration: nil)
        @diagnostics = diagnostics
        @stats = stats
        @fixed = fixed
        @duration = duration
      end

      def print
        print_header
        print_categories
        print_summary
      end

      def exit_code
        error_count.positive? ? 1 : 0
      end

      private

      def print_header
        puts
        puts "  #{UI.bold('Docyard')} v#{VERSION}"
        puts
        puts "  Checking docs..."
        puts
      end

      def print_categories
        CATEGORY_ORDER.each do |category|
          print_category(category)
        end
      end

      def print_category(category)
        items = diagnostics_for(category)
        return if items.empty?

        print_category_header(category, items)
        items.each { |d| puts format_diagnostic(d) }
        puts
      end

      def diagnostics_for(category)
        diagnostics.select { |d| d.category == category }
      end

      def print_category_header(category, items)
        label = CATEGORY_LABELS[category] || category.to_s
        counts = issue_counts(items.count(&:error?), items.count(&:warning?))
        puts "  #{UI.bold(label.ljust(28))} #{counts}"
      end

      def format_diagnostic(diagnostic)
        prefix = diagnostic.error? ? UI.red("error") : UI.yellow("warn ")
        location = diagnostic.location&.ljust(26) || (" " * 26)
        suffix = diagnostic.fixable? ? " #{UI.cyan('[fixable]')}" : ""
        "    #{prefix}   #{location} #{diagnostic.message}#{suffix}"
      end

      def print_summary
        puts "  #{stats_summary}"

        if error_count.zero? && warning_count.zero?
          puts "  #{UI.success('No issues found')}"
        else
          puts "  #{build_issue_summary}"
          print_fixable_hint
        end

        puts "  #{format_duration}" if duration
        puts
      end

      def format_duration
        if duration < 1
          UI.dim("Finished in #{(duration * 1000).round}ms")
        else
          UI.dim("Finished in #{duration.round(2)}s")
        end
      end

      def print_fixable_hint
        return if fixed

        fixable = diagnostics.count(&:fixable?)
        return if fixable.zero?

        puts
        puts "  #{UI.cyan("Run with --fix to auto-fix #{pluralize(fixable, 'issue')}.")}"
      end

      def issue_counts(errors, warnings)
        parts = []
        parts << UI.red(pluralize(errors, "error")) if errors.positive?
        parts << UI.yellow(pluralize(warnings, "warning")) if warnings.positive?
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
        diagnostics.count(&:error?)
      end

      def warning_count
        diagnostics.count(&:warning?)
      end
    end
  end
end
