# frozen_string_literal: true

require "open3"

module Docyard
  module Search
    module PagefindSupport
      def search_enabled?
        config.search.enabled != false
      end

      def pagefind_available?
        _stdout, _stderr, status = Open3.capture3("npx", "pagefind", "--version")
        status.success?
      rescue Errno::ENOENT
        false
      end

      def build_pagefind_args(site_dir)
        args = ["pagefind", "--site", site_dir]

        exclusions = config.search.exclude || []
        exclusions.each do |pattern|
          args += ["--exclude-selectors", pattern]
        end

        args
      end
    end
  end
end
