# frozen_string_literal: true

require "parallel"
require_relative "../rendering/template_resolver"
require_relative "../navigation/page_navigation_builder"
require_relative "../navigation/sidebar/cache"
require_relative "../utils/path_utils"
require_relative "../utils/git_info"
require_relative "root_fallback_generator"
require_relative "error_page_generator"
require_relative "file_writer"

module Docyard
  module Build
    class StaticGenerator
      include FileWriter

      PARALLEL_THRESHOLD = 10

      attr_reader :config, :verbose, :sidebar_cache

      def initialize(config, verbose: false)
        @config = config
        @verbose = verbose
        @sidebar_cache = nil
      end

      def generate
        build_sidebar_cache
        Utils::GitInfo.prefetch_timestamps(docs_path) if show_last_updated?
        copy_custom_landing_page if custom_landing_page?

        markdown_files = collect_markdown_files
        generated_pages = generate_all_pages(markdown_files)
        generate_error_page
        generate_root_fallback_if_needed

        [markdown_files.size, build_verbose_details(generated_pages)]
      ensure
        Utils::GitInfo.clear_cache
      end

      private

      def generate_all_pages(markdown_files)
        Logging.start_buffering
        pages = if markdown_files.size >= PARALLEL_THRESHOLD
                  generate_pages_in_parallel(markdown_files)
                else
                  generate_pages_sequentially(markdown_files)
                end
        Logging.flush_warnings
        pages
      end

      def custom_landing_page?
        File.file?(File.join(docs_path, "index.html"))
      end

      def copy_custom_landing_page
        output_path = File.join(config.build.output, "index.html")
        safe_file_write(output_path) do
          FileUtils.mkdir_p(File.dirname(output_path))
          FileUtils.cp(File.join(docs_path, "index.html"), output_path)
        end
      end

      def collect_markdown_files
        files = Dir.glob(File.join(docs_path, "**", "*.md"))
        files.reject! { |f| f == File.join(docs_path, "index.md") } if custom_landing_page?
        files
      end

      def generate_pages_in_parallel(markdown_files)
        Parallel.map(markdown_files, in_threads: Parallel.processor_count) do |file_path|
          generate_page_with_timing(file_path, thread_local_renderer)
        ensure
          Thread.current[:docyard_build_renderer] = nil
        end
      end

      def generate_pages_sequentially(markdown_files)
        renderer = build_renderer
        markdown_files.map do |file_path|
          generate_page_with_timing(file_path, renderer)
        end
      end

      def generate_page_with_timing(file_path, renderer)
        page_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        output_path = generate_page(file_path, renderer)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - page_start
        [output_path, elapsed]
      end

      def thread_local_renderer
        Thread.current[:docyard_build_renderer] ||= build_renderer
      end

      def build_renderer
        Renderer.new(base_url: config.build.base, config: config)
      end

      def generate_page(markdown_file_path, renderer)
        relative_path = markdown_file_path.delete_prefix("#{docs_path}/")
        output_path = Utils::PathUtils.markdown_to_html_output(relative_path, config.build.output)
        current_path = Utils::PathUtils.markdown_file_to_url(markdown_file_path, docs_path)

        html_content = render_markdown_file(markdown_file_path, current_path, renderer)
        html_content = apply_search_exclusion(html_content, current_path)
        write_output(output_path, html_content)
        output_path
      end

      def apply_search_exclusion(html_content, current_path)
        return html_content unless excluded_from_search?(current_path)

        html_content.gsub("data-pagefind-body", "data-pagefind-ignore")
      end

      def excluded_from_search?(path)
        exclude_patterns = config.search.exclude || []
        exclude_patterns.any? do |pattern|
          next false unless pattern.start_with?("/")

          File.fnmatch(pattern, path, File::FNM_PATHNAME)
        end
      end

      def render_markdown_file(markdown_file_path, current_path, renderer)
        markdown = Markdown.new(File.read(markdown_file_path))
        template_resolver = TemplateResolver.new(markdown.frontmatter, config.data)
        branding = BrandingResolver.new(config).resolve

        navigation = build_navigation_html(template_resolver, current_path, markdown, branding[:header_ctas])
        renderer.render_file(markdown_file_path, **navigation, branding: branding,
                                                               template_options: template_resolver.to_options,
                                                               current_path: current_path)
      end

      def build_navigation_html(template_resolver, current_path, markdown, header_ctas)
        navigation_builder.build(
          current_path: current_path,
          markdown: markdown,
          header_ctas: header_ctas,
          show_sidebar: template_resolver.show_sidebar?
        )
      end

      def navigation_builder
        @navigation_builder ||= Navigation::PageNavigationBuilder.new(
          docs_path: docs_path,
          config: config,
          sidebar_cache: sidebar_cache,
          base_url: config.build.base
        )
      end

      def write_output(output_path, html_content)
        safe_file_write(output_path) do
          FileUtils.mkdir_p(File.dirname(output_path))
          File.write(output_path, html_content)
        end
      end

      def build_sidebar_cache
        @sidebar_cache = Sidebar::Cache.new(
          docs_path: docs_path,
          config: config
        )
        @sidebar_cache.build
      end

      def show_last_updated?
        config.repo.url && config.repo.last_updated != false
      end

      def docs_path
        config.source
      end

      def build_verbose_details(generated_pages)
        return nil unless verbose

        generated_pages.map do |output_path, elapsed|
          path = output_path.delete_prefix("#{config.build.output}/")
          "#{path.ljust(30)} #{format('%<t>.2fs', t: elapsed)}"
        end
      end

      def generate_error_page
        ErrorPageGenerator.new(
          config: config,
          docs_path: docs_path,
          renderer: build_renderer
        ).generate
      end

      def generate_root_fallback_if_needed
        generator = RootFallbackGenerator.new(
          config: config,
          docs_path: docs_path,
          sidebar_cache: sidebar_cache,
          renderer: build_renderer
        )
        generator.generate_if_needed
      end
    end
  end
end
