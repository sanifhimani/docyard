# frozen_string_literal: true

module Docyard
  module Build
    class StepRunner
      STEP_SHORT_LABELS = {
        "Generating pages" => "Pages",
        "Social cards" => "Cards",
        "Bundling assets" => "Assets",
        "Copying files" => "Files",
        "Generating SEO" => "SEO",
        "Indexing search" => "Search"
      }.freeze

      attr_reader :verbose, :step_timings

      def initialize(verbose: false)
        @verbose = verbose
        @step_timings = []
      end

      def run(label, &)
        print "  #{label.ljust(20)}#{UI.dim('in progress')}"
        $stdout.flush
        result, details, elapsed = execute(label, &)
        print_result(label, result, elapsed)
        print_details(details) if verbose && details&.any?
        result
      end

      def print_timing_breakdown
        total = step_timings.sum { |t| t[:elapsed] }
        sorted = step_timings.sort_by { |t| -t[:elapsed] }

        puts "  #{UI.bold('Timing:')}"
        sorted.each { |timing| puts "    #{UI.dim(format_timing_line(timing, total))}" }
        puts
      end

      private

      def execute(label)
        step_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result, details = yield
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - step_start
        @step_timings << { label: STEP_SHORT_LABELS.fetch(label, label), elapsed: elapsed }
        [result, details, elapsed]
      end

      def print_result(label, result, elapsed)
        timing_suffix = verbose ? UI.dim(" in #{format('%<t>.2fs', t: elapsed)}") : ""
        print "\r  #{label.ljust(20)}#{UI.green(format_result(label, result))}#{timing_suffix}\n"
        $stdout.flush
      end

      def print_details(details)
        details.each { |detail| puts "      #{UI.dim(detail)}" }
      end

      def format_result(label, result)
        case label
        when "Generating pages" then "done (#{result} pages)"
        when "Social cards" then "done (#{result} cards)"
        when "Bundling assets" then format_assets_result(result)
        when "Copying files" then "done (#{result} files)"
        when "Generating SEO" then "done (#{result.join(', ')})"
        when "Indexing search" then "done (#{result} pages indexed)"
        else "done"
        end
      end

      def format_assets_result(result)
        css, js = result
        "done (#{format_size(css)} CSS, #{format_size(js)} JS)"
      end

      def format_size(bytes)
        kb = bytes / 1024.0
        kb >= 1000 ? format("%.1f MB", kb / 1024.0) : format("%.1f KB", kb)
      end

      def format_timing_line(timing, total)
        label = timing[:label].ljust(12)
        secs = format("%<t>5.2fs", t: timing[:elapsed])
        pct = total.positive? ? (timing[:elapsed] / total * 100).round : 0
        "#{label} #{secs} (#{format('%<p>2d', p: pct)}%)"
      end
    end
  end
end
