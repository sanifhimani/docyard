# frozen_string_literal: true

require "open3"

module Docyard
  module Search
    class BuildIndexer
      include PagefindSupport

      attr_reader :config, :output_dir, :verbose

      def initialize(config, verbose: false)
        @config = config
        @output_dir = config.build.output
        @verbose = verbose
      end

      def index
        return [0, nil] unless search_enabled?
        return [0, nil] unless pagefind_available?

        run_pagefind
      end

      private

      def run_pagefind
        command = pagefind_command
        args = build_pagefind_args(output_dir)

        stdout, stderr, status = Open3.capture3(*command, *args)

        if status.success?
          count = extract_page_count(stdout)
          details = verbose ? collect_index_details : nil
          [count, details]
        else
          Docyard.logger.warn("Search indexing failed: #{stderr}") if verbose
          [0, nil]
        end
      end

      def extract_page_count(output)
        if output =~ /Indexed (\d+) page/i
          Regexp.last_match(1).to_i
        else
          0
        end
      end

      def collect_index_details
        indexed, excluded = classify_pages
        format_index_details(indexed, excluded)
      end

      def classify_pages
        indexed = []
        excluded = []

        Dir.glob(File.join(output_dir, "**", "index.html")).each do |file|
          path = extract_page_path(file)
          classify_page(File.read(file), path, indexed, excluded)
        end

        [indexed, excluded]
      end

      def extract_page_path(file)
        path = file.delete_prefix("#{output_dir}/").delete_suffix("/index.html")
        path.empty? ? "/" : path
      end

      def classify_page(content, path, indexed, excluded)
        if content.include?("data-pagefind-body")
          indexed << path
        elsif content.include?("data-pagefind-ignore")
          excluded << path
        end
      end

      def format_index_details(indexed, excluded)
        details = indexed.sort
        excluded.sort.each { |path| details << "(excluded: #{path})" } if excluded.any?
        details
      end
    end
  end
end
