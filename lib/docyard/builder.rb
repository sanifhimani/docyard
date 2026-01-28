# frozen_string_literal: true

require "fileutils"

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
      print_header
      prepare_output_directory
      run_build_steps
      print_summary
      true
    rescue StandardError => e
      print_error(e)
      false
    end

    private

    def print_header
      puts
      puts "  Docyard v#{VERSION}"
      puts
      puts "  Building to #{config.build.output}/..."
      puts
    end

    def run_build_steps
      run_step("Generating pages") { generate_static_pages }
      run_step("Bundling assets") { bundle_assets }
      run_step("Copying files") { copy_static_files }
      run_step("Generating SEO") { generate_seo_files }
      run_step("Indexing search") { generate_search_index }
    end

    def run_step(label)
      print "  #{label.ljust(20)}in progress"
      $stdout.flush
      result, details = yield
      print "\r  #{label.ljust(20)}#{format_result(label, result)}\n"
      $stdout.flush
      print_verbose_details(details) if verbose && details&.any?
      result
    end

    def print_verbose_details(details)
      details.each { |detail| puts "      #{detail}" }
    end

    def format_result(label, result)
      case label
      when "Generating pages"
        "done (#{result} pages)"
      when "Bundling assets"
        css, js = result
        "done (#{format_size(css)} CSS, #{format_size(js)} JS)"
      when "Copying files"
        "done (#{result} files)"
      when "Generating SEO"
        "done (#{result.join(', ')})"
      when "Indexing search"
        "done (#{result} pages indexed)"
      else
        "done"
      end
    end

    def format_size(bytes)
      kb = bytes / 1024.0
      if kb >= 1000
        format("%.1f MB", kb / 1024.0)
      else
        format("%.1f KB", kb)
      end
    end

    def print_error(error)
      puts "failed"
      puts
      puts "  Error: #{error.message}"
      puts "  #{error.backtrace.first}" if verbose
      puts
    end

    def print_summary
      elapsed = Time.now - start_time
      size = calculate_output_size
      puts
      puts "  Build complete in #{format('%.2fs', elapsed)}"
      puts "  Output: #{config.build.output}/ (#{format_size(size)})"
      puts
    end

    def calculate_output_size
      Dir.glob(File.join(config.build.output, "**", "*"))
        .select { |f| File.file?(f) }
        .sum { |f| File.size(f) }
    end

    def prepare_output_directory
      output_dir = config.build.output
      FileUtils.rm_rf(output_dir) if clean && Dir.exist?(output_dir)
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
      result = bundler.bundle
      [result, nil]
    end

    def copy_static_files
      require_relative "build/file_copier"
      copier = Build::FileCopier.new(config, verbose: verbose)
      copier.copy
    end

    def generate_seo_files
      require_relative "build/sitemap_generator"
      sitemap_result = Build::SitemapGenerator.new(config).generate

      require_relative "build/llms_txt_generator"
      Build::LlmsTxtGenerator.new(config).generate

      File.write(File.join(config.build.output, "robots.txt"), robots_txt_content)

      result = ["sitemap.xml", "robots.txt", "llms.txt"]
      details = ["sitemap.xml (#{sitemap_result} URLs)", "robots.txt", "llms.txt", "llms-full.txt"]
      [result, details]
    end

    def generate_search_index
      indexer = Search::BuildIndexer.new(config, verbose: verbose)
      indexer.index
    end

    def robots_txt_content
      base = config.build.base
      base = "#{base}/" unless base.end_with?("/")

      <<~ROBOTS
        User-agent: *
        Allow: /

        Sitemap: #{base}sitemap.xml
      ROBOTS
    end
  end
end
