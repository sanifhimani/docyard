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

        log "Generating search index..."

        unless pagefind_available?
          warn_pagefind_missing
          return 0
        end

        run_pagefind
      end

      private

      def warn_pagefind_missing
        log_warning "[!] Search index skipped: Pagefind not found"
        log_warning "    Install with: npm install -g pagefind"
        log_warning "    Or run: npx pagefind --site #{output_dir}"
      end

      def run_pagefind
        args = build_pagefind_args(output_dir)
        log "Running: npx #{args.join(' ')}" if verbose

        stdout, stderr, status = Open3.capture3(PAGEFIND_COMMAND, *args)

        if status.success?
          page_count = extract_page_count(stdout)
          log "[+] Generated search index (#{page_count} pages indexed)"
          page_count
        else
          log_warning "[!] Search indexing failed: #{stderr}"
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

      def log(message)
        Docyard.logger.info(message)
      end

      def log_warning(message)
        Docyard.logger.warn(message)
      end
    end
  end
end
