# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "open3"
require "tty-progressbar"

module Docyard
  class DevSearchIndexer
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
      run_pagefind
      @pagefind_path = File.join(temp_dir, "pagefind")

      log_success
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

    def search_enabled?
      config.search.enabled != false
    end

    def pagefind_available?
      _stdout, _stderr, status = Open3.capture3("npx", "pagefind", "--version")
      status.success?
    rescue Errno::ENOENT
      warn "[!] Search disabled: Pagefind not found (npm install -g pagefind)"
      false
    end

    def generate_html_files
      markdown_files = Dir.glob(File.join(docs_path, "**", "*.md"))
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
      {
        site_title: config.site.title || Constants::DEFAULT_SITE_TITLE,
        site_description: config.site.description || "",
        search_enabled: true,
        search_placeholder: config.search.placeholder || "Search documentation..."
      }
    end

    def run_pagefind
      args = build_pagefind_args
      stdout, stderr, status = Open3.capture3("npx", *args)

      raise "Pagefind failed: #{stderr}" unless status.success?

      stdout
    end

    def build_pagefind_args
      args = ["pagefind", "--site", temp_dir]

      exclusions = config.search.exclude || []
      exclusions.each do |pattern|
        args += ["--exclude-selectors", pattern]
      end

      args
    end

    def log_success
      page_count = Dir.glob(File.join(temp_dir, "**", "*.html")).size
      puts "=> Search index generated (#{page_count} pages)"
      puts "=> Temp directory: #{temp_dir}" if ENV["DOCYARD_DEBUG"]
    end
  end
end
