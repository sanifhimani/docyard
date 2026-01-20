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
