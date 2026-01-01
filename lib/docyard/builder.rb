# frozen_string_literal: true

require "fileutils"
require "tty-progressbar"

module Docyard
  class Builder
    attr_reader :config, :clean, :verbose, :start_time

    def initialize(clean: true, verbose: false)
      @config = Config.new
      @clean = clean
      @verbose = verbose
      @start_time = Time.now
    end

    def build
      prepare_output_directory
      log "Building static site..."

      pages_built = generate_static_pages
      bundles_created = bundle_assets
      assets_copied = copy_static_files
      generate_seo_files
      pages_indexed = generate_search_index

      display_summary(pages_built, bundles_created, assets_copied, pages_indexed)
      true
    rescue StandardError => e
      error "Build failed: #{e.message}"
      error e.backtrace.first if verbose
      false
    end

    private

    def prepare_output_directory
      output_dir = config.build.output_dir

      if clean && Dir.exist?(output_dir)
        log "[✓] Cleaning #{output_dir}/ directory"
        FileUtils.rm_rf(output_dir)
      end

      FileUtils.mkdir_p(output_dir)
    end

    def generate_static_pages
      require_relative "build/static_generator"
      generator = Build::StaticGenerator.new(config, verbose: verbose)
      generator.generate
    end

    def bundle_assets
      require_relative "build/asset_bundler"
      bundler = Build::AssetBundler.new(config, verbose: verbose)
      bundler.bundle
    end

    def copy_static_files
      require_relative "build/file_copier"
      copier = Build::FileCopier.new(config, verbose: verbose)
      copier.copy
    end

    def generate_seo_files
      require_relative "build/sitemap_generator"
      sitemap_gen = Build::SitemapGenerator.new(config)
      sitemap_gen.generate

      File.write(File.join(config.build.output_dir, "robots.txt"), robots_txt_content)
      log "[+] Generated robots.txt"
    end

    def generate_search_index
      indexer = Search::BuildIndexer.new(config, verbose: verbose)
      indexer.index
    end

    def robots_txt_content
      base_url = config.build.base_url
      base_url = "#{base_url}/" unless base_url.end_with?("/")

      <<~ROBOTS
        User-agent: *
        Allow: /

        Sitemap: #{base_url}sitemap.xml
      ROBOTS
    end

    def display_summary(pages, bundles, assets, indexed = 0)
      elapsed = Time.now - start_time

      puts "\n#{'=' * 50}"
      puts "Build complete in #{format('%.2f', elapsed)}s"
      puts "Output: #{config.build.output_dir}/"

      summary = "#{pages} pages, #{bundles} bundles, #{assets} static files"
      summary += ", #{indexed} pages indexed" if indexed.positive?
      puts summary

      puts "=" * 50
    end

    def log(message)
      puts message
    end

    def error(message)
      warn "[ERROR] #{message}"
    end
  end
end
