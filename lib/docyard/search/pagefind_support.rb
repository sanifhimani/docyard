# frozen_string_literal: true

module Docyard
  module Search
    module PagefindSupport
      def search_enabled?
        config.search.enabled != false
      end

      def pagefind_available?
        !PagefindBinary.executable.nil?
      end

      def pagefind_command
        executable = PagefindBinary.executable
        return nil unless executable

        executable == "npx" ? %w[npx pagefind] : [executable]
      end

      def build_pagefind_args(site_dir)
        args = ["--site", site_dir, "--output-subdir", "_docyard/pagefind"]

        exclusions = config.search.exclude || []
        exclusions.each do |pattern|
          next if pattern.start_with?("/")

          args += ["--exclude-selectors", pattern]
        end

        args
      end
    end
  end
end
