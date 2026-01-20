# frozen_string_literal: true

require "open3"

module Docyard
  module Utils
    class GitInfo
      TIME_UNITS = [
        [60, "minute"],
        [3600, "hour"],
        [86_400, "day"],
        [604_800, "week"],
        [2_592_000, "month"],
        [31_536_000, "year"]
      ].freeze

      class << self
        attr_accessor :timestamp_cache

        def prefetch_timestamps(docs_path = "docs")
          return unless git_repository?

          @timestamp_cache = fetch_all_timestamps(docs_path)
        end

        def clear_cache
          @timestamp_cache = nil
        end

        def cached_timestamp(file_path)
          return nil unless @timestamp_cache

          @timestamp_cache[file_path]
        end

        def git_repository?
          File.directory?(".git") || system("git", "rev-parse", "--git-dir", out: File::NULL, err: File::NULL)
        end

        private

        def fetch_all_timestamps(docs_path)
          output, _, status = Open3.capture3("git", "log", "--pretty=format:%cI", "--name-only", "--", "#{docs_path}/")
          return {} unless status.success?

          parse_git_log_output(output)
        end

        def parse_git_log_output(output)
          timestamps = {}
          current_timestamp = nil

          output.each_line do |line|
            line = line.strip
            next if line.empty?

            if line.match?(/^\d{4}-\d{2}-\d{2}T/)
              current_timestamp = Time.parse(line)
            elsif current_timestamp && !timestamps.key?(line)
              timestamps[line] = current_timestamp
            end
          end

          timestamps
        end
      end

      attr_reader :repo_url, :branch, :edit_path

      def initialize(repo_url:, branch: "main", edit_path: "docs")
        @repo_url = repo_url
        @branch = branch
        @edit_path = edit_path
      end

      def edit_url(file_path)
        return nil unless repo_url

        relative_path = extract_relative_path(file_path)
        return nil unless relative_path

        normalized_url = repo_url.chomp("/")
        "#{normalized_url}/edit/#{branch}/#{edit_path}/#{relative_path}"
      end

      def last_updated(file_path)
        return nil unless file_path && File.exist?(file_path)
        return nil unless self.class.git_repository?

        timestamp = git_last_commit_time(file_path)
        return nil unless timestamp

        {
          time: timestamp,
          iso: timestamp.iso8601,
          formatted: format_datetime(timestamp),
          formatted_short: format_date_short(timestamp),
          relative: relative_time(timestamp)
        }
      end

      private

      def extract_relative_path(file_path)
        return nil unless file_path

        match = file_path.match(%r{docs/(.+)$})
        match ? match[1] : nil
      end

      def git_last_commit_time(file_path)
        cached = self.class.cached_timestamp(file_path)
        return cached if cached

        fetch_single_timestamp(file_path)
      end

      def fetch_single_timestamp(file_path)
        output, _, status = Open3.capture3("git", "log", "-1", "--format=%cI", "--", file_path)
        return nil unless status.success?
        return nil if output.strip.empty?

        Time.parse(output.strip)
      rescue ArgumentError
        nil
      end

      def format_datetime(time)
        time.strftime("%B %-d, %Y at %-I:%M %p")
      end

      def format_date_short(time)
        time.strftime("%b %-d, %Y")
      end

      def relative_time(time)
        seconds = Time.now - time
        return "just now" if seconds < TIME_UNITS.first.first

        divisor, unit = find_time_unit(seconds)
        pluralize((seconds / divisor).to_i, unit)
      end

      def find_time_unit(seconds)
        TIME_UNITS.reverse_each do |threshold, unit|
          return [threshold, unit] if seconds >= threshold
        end
        TIME_UNITS.first
      end

      def pluralize(count, word)
        suffix = count == 1 ? "" : "s"
        "#{count} #{word}#{suffix} ago"
      end
    end
  end
end
