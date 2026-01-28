# frozen_string_literal: true

require "fileutils"

module Docyard
  class Builder
    STEP_SHORT_LABELS = {
      "Generating pages" => "Pages",
      "Bundling assets" => "Assets",
      "Copying files" => "Files",
      "Generating SEO" => "SEO",
      "Indexing search" => "Search"
    }.freeze

    attr_reader :config, :clean, :verbose, :start_time

    def initialize(clean: true, verbose: false)
      @config = Config.new
      @clean = clean
      @verbose = verbose
      @start_time = Time.now
      @step_timings = []
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
      puts "  #{UI.bold('Docyard')} v#{VERSION}"
      puts
      puts "  Building to #{UI.dim("#{config.build.output}/")}..."
      puts
    end

    def run_build_steps
      run_step("Generating pages") { generate_static_pages }
      run_step("Bundling assets") { bundle_assets }
      run_step("Copying files") { copy_static_files }
      run_step("Generating SEO") { generate_seo_files }
      run_step("Indexing search") { generate_search_index }
    end

    def run_step(label, &)
      print "  #{label.ljust(20)}#{UI.dim('in progress')}"
      $stdout.flush
      result, details, elapsed = execute_step(label, &)
      print_step_result(label, result, elapsed)
      print_verbose_details(details) if verbose && details&.any?
      result
    end

    def execute_step(label)
      step_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result, details = yield
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - step_start
      @step_timings << { label: STEP_SHORT_LABELS.fetch(label, label), elapsed: elapsed }
      [result, details, elapsed]
    end

    def print_step_result(label, result, elapsed)
      timing_suffix = verbose ? UI.dim(" in #{format('%<t>.2fs', t: elapsed)}") : ""
      print "\r  #{label.ljust(20)}#{UI.green(format_result(label, result))}#{timing_suffix}\n"
      $stdout.flush
    end

    def print_verbose_details(details)
      details.each { |detail| puts "      #{UI.dim(detail)}" }
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
      puts UI.error("failed")
      puts
      puts "  #{UI.error('Error:')} #{error.message}"
      puts "  #{error.backtrace.first}" if verbose
      puts
    end

    def print_summary # rubocop:disable Metrics/AbcSize
      elapsed = Time.now - start_time
      size = calculate_output_size
      puts
      puts "  #{UI.success('Build complete')} in #{format('%.2fs', elapsed)}"
      puts "  #{UI.dim("Output: #{config.build.output}/ (#{format_size(size)})")}"
      puts
      print_timing_breakdown if verbose
    end

    def print_timing_breakdown
      total = @step_timings.sum { |t| t[:elapsed] }
      sorted = @step_timings.sort_by { |t| -t[:elapsed] }

      puts "  #{UI.bold('Timing:')}"
      sorted.each { |timing| puts "    #{UI.dim(format_timing_line(timing, total))}" }
      puts
    end

    def format_timing_line(timing, total)
      label = timing[:label].ljust(12)
      secs = format("%<t>5.2fs", t: timing[:elapsed])
      pct = total.positive? ? (timing[:elapsed] / total * 100).round : 0
      "#{label} #{secs} (#{format('%<p>2d', p: pct)}%)"
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
      [Build::AssetBundler.new(config, verbose: verbose).bundle, nil]
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
