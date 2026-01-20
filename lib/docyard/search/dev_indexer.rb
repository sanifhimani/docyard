# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "open3"
require "parallel"
require "tty-progressbar"
require_relative "../utils/path_utils"

module Docyard
  module Search
    class DevIndexer
      include PagefindSupport

      PARALLEL_THRESHOLD = 10

      attr_reader :docs_path, :config, :temp_dir, :pagefind_path

      def initialize(docs_path:, config:)
        @docs_path = docs_path
        @config = config
        @temp_dir = nil
        @pagefind_path = nil
      end

      def generate
        return unless search_enabled?
        return unless pagefind_available?

        @temp_dir = Dir.mktmpdir("docyard-search-")
        generate_html_files
        page_count = run_pagefind
        @pagefind_path = File.join(temp_dir, "_docyard", "pagefind")

        log_success(page_count)
        pagefind_path
      rescue StandardError => e
        Docyard.logger.warn("Search index generation failed: #{e.message}")
        cleanup
        nil
      end

      def cleanup
        return unless temp_dir && Dir.exist?(temp_dir)

        FileUtils.rm_rf(temp_dir)
      end

      private

      def pagefind_available?
        result = super
        Docyard.logger.warn("Search disabled: Pagefind not found (npm install -g pagefind)") unless result
        result
      end

      def generate_html_files
        markdown_files = Dir.glob(File.join(docs_path, "**", "*.md"))
        markdown_files = filter_excluded_files(markdown_files)
        markdown_files = filter_non_indexable_files(markdown_files)

        progress = TTY::ProgressBar.new(
          "Indexing search [:bar] :current/:total (:percent)",
          total: markdown_files.size,
          width: 50
        )
        mutex = Mutex.new

        if markdown_files.size >= PARALLEL_THRESHOLD
          generate_files_in_parallel(markdown_files, progress, mutex)
        else
          generate_files_sequentially(markdown_files, progress)
        end
      end

      def generate_files_in_parallel(markdown_files, progress, mutex)
        Parallel.each(markdown_files, in_threads: Parallel.processor_count) do |file_path|
          renderer = thread_local_renderer
          generate_html_file(file_path, renderer)
          mutex.synchronize { progress.advance }
        end
      end

      def generate_files_sequentially(markdown_files, progress)
        renderer = Renderer.new(base_url: "/", config: config)
        markdown_files.each do |file_path|
          generate_html_file(file_path, renderer)
          progress.advance
        end
      end

      def thread_local_renderer
        Thread.current[:docyard_search_renderer] ||= Renderer.new(base_url: "/", config: config)
      end

      def filter_excluded_files(files)
        exclude_patterns = config.search.exclude || []
        return files if exclude_patterns.empty?

        files.reject do |file_path|
          url_path = file_to_url_path(file_path)
          exclude_patterns.any? { |pattern| File.fnmatch(pattern, url_path, File::FNM_PATHNAME) }
        end
      end

      def filter_non_indexable_files(files)
        files.reject do |file_path|
          content = File.read(file_path)
          markdown = Markdown.new(content)
          frontmatter = markdown.frontmatter

          uses_splash_template?(frontmatter)
        end
      end

      def uses_splash_template?(frontmatter)
        return true if frontmatter["template"] == "splash"
        return true if frontmatter.key?("landing")

        frontmatter.key?("hero") || frontmatter.key?("features")
      end

      def file_to_url_path(file_path)
        Utils::PathUtils.markdown_file_to_url(file_path, docs_path)
      end

      def generate_html_file(markdown_file, renderer)
        relative_path = markdown_file.delete_prefix("#{docs_path}/")
        output_path = determine_output_path(relative_path)

        html = renderer.render_for_search(markdown_file)

        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, html)
      end

      def determine_output_path(relative_path)
        Utils::PathUtils.markdown_to_html_output(relative_path, temp_dir)
      end

      def run_pagefind
        args = build_pagefind_args(temp_dir)
        stdout, stderr, status = Open3.capture3("npx", *args)

        raise "Pagefind failed: #{stderr}" unless status.success?

        extract_page_count(stdout)
      end

      def extract_page_count(output)
        match = output.match(/Indexed (\d+) page/i)
        match ? match[1].to_i : 0
      end

      def log_success(page_count)
        Docyard.logger.info("* Search index generated (#{page_count} pages indexed)")
        Docyard.logger.debug("* Temp directory: #{temp_dir}")
      end
    end
  end
end
