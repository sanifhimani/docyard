# frozen_string_literal: true

require "open3"

module Docyard
  module Search
    class BuildIndexer
      include PagefindSupport

      PAGEFIND_COMMAND = "npx"

      attr_reader :config, :output_dir, :verbose

      def initialize(config, verbose: false)
        @config = config
        @output_dir = config.build.output
        @verbose = verbose
      end

      def index
        return 0 unless search_enabled?
        return 0 unless pagefind_available?

        run_pagefind
      end

      private

      def run_pagefind
        args = build_pagefind_args(output_dir)

        stdout, stderr, status = Open3.capture3(PAGEFIND_COMMAND, *args)

        if status.success?
          extract_page_count(stdout)
        else
          Docyard.logger.warn("Search indexing failed: #{stderr}") if verbose
          0
        end
      end

      def extract_page_count(output)
        if output =~ /Indexed (\d+) page/i
          Regexp.last_match(1).to_i
        else
          0
        end
      end
    end
  end
end
