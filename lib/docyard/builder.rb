# frozen_string_literal: true

require "fileutils"
require_relative "build/step_runner"

module Docyard
  class Builder
    attr_reader :config, :clean, :verbose, :strict, :start_time

    def initialize(clean: true, verbose: false, strict: false)
      @config = Config.new
      @clean = clean
      @verbose = verbose
      @strict = strict || config.build.strict
      @start_time = Time.now
      @step_runner = Build::StepRunner.new(verbose: verbose)
    end

    def build
      return false unless passes_validation?

      print_header
      prepare_output_directory
      execute_build_steps
      print_summary
      true
    rescue StandardError => e
      print_error(e)
      false
    end

    private

    def print_header
      puts
      puts "  #{UI.bold('Docyard')} v#{VERSION}"
      puts
      puts "  Building to #{UI.dim("#{config.build.output}/")}..."
      puts
    end

    def passes_validation?
      require_relative "build/validator"
      validator = Build::Validator.new(config, strict: strict)
      return true if validator.valid?

      validator.print_errors
      false
    end

    def execute_build_steps
      @step_runner.run("Generating pages") { generate_static_pages }
      @step_runner.run("Bundling assets") { bundle_assets }
      @step_runner.run("Copying files") { copy_static_files }
      @step_runner.run("Generating SEO") { generate_seo_files }
      @step_runner.run("Indexing search") { generate_search_index }
    end

    def print_error(error)
      puts UI.error("failed")
      puts
      puts "  #{UI.error('Error:')} #{error.message}"
      puts "  #{error.backtrace.first}" if verbose
      puts
    end

    def print_summary
      puts
      puts "  #{UI.success('Build complete')} in #{format('%.2fs', build_duration)}"
      puts "  #{UI.dim(output_summary)}"
      puts
      @step_runner.print_timing_breakdown if verbose
    end

    def build_duration
      Time.now - start_time
    end

    def output_summary
      "Output: #{config.build.output}/ (#{format_size(calculate_output_size)})"
    end

    def format_size(bytes)
      kb = bytes / 1024.0
      kb >= 1000 ? format("%.1f MB", kb / 1024.0) : format("%.1f KB", kb)
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
      Build::StaticGenerator.new(config, verbose: verbose).generate
    end

    def bundle_assets
      require_relative "build/asset_bundler"
      [Build::AssetBundler.new(config, verbose: verbose).bundle, nil]
    end

    def copy_static_files
      require_relative "build/file_copier"
      Build::FileCopier.new(config, verbose: verbose).copy
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
      Search::BuildIndexer.new(config, verbose: verbose).index
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
