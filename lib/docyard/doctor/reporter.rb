# frozen_string_literal: true

module Docyard
  class DoctorReporter
    attr_reader :results, :stats

    def initialize(results, stats = {})
      @results = results
      @stats = stats
    end

    def print
      puts
      print_broken_links
      print_missing_images
      print_orphan_pages
      print_summary
    end

    def exit_code
      error_count.positive? ? 1 : 0
    end

    private

    def print_broken_links
      issues = results[:broken_links]
      return if issues.empty?

      puts "  Broken Links"
      issues.each do |issue|
        location = "#{issue.file}:#{issue.line}"
        puts "    #{location.ljust(36)} #{issue.target}"
      end
      puts
    end

    def print_missing_images
      issues = results[:missing_images]
      return if issues.empty?

      puts "  Missing Images"
      issues.each do |issue|
        location = "#{issue.file}:#{issue.line}"
        puts "    #{location.ljust(36)} #{issue.target}"
      end
      puts
    end

    def print_orphan_pages
      orphans = results[:orphan_pages]
      return if orphans.empty?

      puts "  Orphan Pages"
      orphans.each do |orphan|
        puts "    #{orphan[:file]}"
      end
      puts
    end

    def print_summary
      if error_count.zero? && warning_count.zero?
        puts "  Checked #{stats_summary}"
        puts "  No issues found"
      else
        puts "  #{build_summary}"
      end
      puts
    end

    def stats_summary
      stat_parts.compact.join(", ")
    end

    def stat_parts
      [
        format_stat(:files, "file"),
        format_stat(:links, "link"),
        format_stat(:images, "image")
      ]
    end

    def format_stat(key, label)
      stats[key] && pluralize(stats[key], label)
    end

    def build_summary
      parts = []
      parts << pluralize(error_count, "error") if error_count.positive?
      parts << pluralize(warning_count, "warning") if warning_count.positive?
      parts.join(", ")
    end

    def pluralize(count, word)
      count == 1 ? "#{count} #{word}" : "#{count} #{word}s"
    end

    def error_count
      results[:broken_links].size + results[:missing_images].size
    end

    def warning_count
      results[:orphan_pages].size
    end
  end
end
