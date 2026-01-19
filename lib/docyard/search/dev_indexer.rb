# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "open3"
require "tty-progressbar"

module Docyard
  module Search
    class DevIndexer
      include PagefindSupport

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
        warn "[!] Search index generation failed: #{e.message}"
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
        warn "[!] Search disabled: Pagefind not found (npm install -g pagefind)" unless result
        result
      end

      def generate_html_files
        markdown_files = Dir.glob(File.join(docs_path, "**", "*.md"))
        markdown_files = filter_excluded_files(markdown_files)
        markdown_files = filter_non_indexable_files(markdown_files)
        renderer = Renderer.new(base_url: "/", config: config)

        progress = TTY::ProgressBar.new(
          "Indexing search [:bar] :current/:total (:percent)",
          total: markdown_files.size,
          width: 50
        )

        markdown_files.each do |file_path|
          generate_html_file(file_path, renderer)
          progress.advance
        end
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
        relative_path = file_path.delete_prefix("#{docs_path}/")
        base_name = File.basename(relative_path, ".md")
        dir_name = File.dirname(relative_path)

        if base_name == "index"
          dir_name == "." ? "/" : "/#{dir_name}"
        else
          dir_name == "." ? "/#{base_name}" : "/#{dir_name}/#{base_name}"
        end
      end

      def generate_html_file(markdown_file, renderer)
        relative_path = markdown_file.delete_prefix("#{docs_path}/")
        output_path = determine_output_path(relative_path)

        html = renderer.render_file(markdown_file, branding: branding_options)

        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, html)
      end

      def determine_output_path(relative_path)
        base_name = File.basename(relative_path, ".md")
        dir_name = File.dirname(relative_path)

        if base_name == "index"
          File.join(temp_dir, dir_name, "index.html")
        else
          File.join(temp_dir, dir_name, base_name, "index.html")
        end
      end

      def branding_options
        BrandingResolver.new(config).resolve
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
        puts "* Search index generated (#{page_count} pages indexed)"
        puts "* Temp directory: #{temp_dir}" if ENV["DOCYARD_DEBUG"]
      end
    end
  end
end
