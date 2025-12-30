# frozen_string_literal: true

require "open3"

module Docyard
  module Build
    class SearchIndexer
      PAGEFIND_COMMAND = "npx"
      PAGEFIND_ARGS = ["pagefind"].freeze

      attr_reader :config, :output_dir, :verbose

      def initialize(config, verbose: false)
        @config = config
        @output_dir = config.build.output_dir
        @verbose = verbose
      end

      def index
        return 0 unless search_enabled?

        log "Generating search index..."

        unless pagefind_available?
          warn_pagefind_missing
          return 0
        end

        run_pagefind
      end

      private

      def search_enabled?
        config.search.enabled != false
      end

      def pagefind_available?
        _stdout, _stderr, status = Open3.capture3("npx", "pagefind", "--version")
        status.success?
      rescue Errno::ENOENT
        false
      end

      def warn_pagefind_missing
        log_warning "[!] Search index skipped: Pagefind not found"
        log_warning "    Install with: npm install -g pagefind"
        log_warning "    Or run: npx pagefind --site #{output_dir}"
      end

      def run_pagefind
        args = build_pagefind_args
        log "Running: npx pagefind #{args.join(' ')}" if verbose

        stdout, stderr, status = Open3.capture3(PAGEFIND_COMMAND, *PAGEFIND_ARGS, *args)

        if status.success?
          page_count = extract_page_count(stdout)
          log "[+] Generated search index (#{page_count} pages indexed)"
          page_count
        else
          log_warning "[!] Search indexing failed: #{stderr}"
          0
        end
      end

      def build_pagefind_args
        args = ["--site", output_dir]

        exclusions = config.search.exclude || []
        exclusions.each do |pattern|
          args += ["--exclude-selectors", pattern]
        end

        args
      end

      def extract_page_count(output)
        if output =~ /Indexed (\d+) page/i
          Regexp.last_match(1).to_i
        else
          0
        end
      end

      def log(message)
        puts message
      end

      def log_warning(message)
        warn message
      end
    end
  end
end
