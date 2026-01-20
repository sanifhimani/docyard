# frozen_string_literal: true

require "parallel"
require "tty-progressbar"
require_relative "../rendering/template_resolver"
require_relative "../navigation/page_navigation_builder"
require_relative "../navigation/sidebar/cache"
require_relative "../utils/path_utils"
require_relative "../utils/git_info"

module Docyard
  module Build
    class StaticGenerator
      PARALLEL_THRESHOLD = 10

      attr_reader :config, :verbose, :sidebar_cache

      def initialize(config, verbose: false)
        @config = config
        @verbose = verbose
        @sidebar_cache = nil
      end

      def generate
        build_sidebar_cache
        Utils::GitInfo.prefetch_timestamps("docs") if config.branding.show_last_updated
        copy_custom_landing_page if custom_landing_page?

        markdown_files = collect_markdown_files
        Docyard.logger.info("\n[✓] Found #{markdown_files.size} markdown files")

        generate_all_pages(markdown_files)
        generate_error_page

        markdown_files.size
      ensure
        Utils::GitInfo.clear_cache
      end

      private

      def generate_all_pages(markdown_files)
        progress = TTY::ProgressBar.new(
          "Generating pages [:bar] :current/:total (:percent)",
          total: markdown_files.size,
          width: 50
        )
        mutex = Mutex.new

        if markdown_files.size >= PARALLEL_THRESHOLD
          generate_pages_in_parallel(markdown_files, progress, mutex)
        else
          generate_pages_sequentially(markdown_files, progress)
        end
      end

      def custom_landing_page?
        File.file?("docs/index.html")
      end

      def copy_custom_landing_page
        output_path = File.join(config.build.output, "index.html")
        FileUtils.mkdir_p(File.dirname(output_path))
        FileUtils.cp("docs/index.html", output_path)
        log "[✓] Copied custom landing page (index.html)"
      end

      def collect_markdown_files
        files = Dir.glob(File.join("docs", "**", "*.md"))
        files.reject! { |f| f == "docs/index.md" } if custom_landing_page?
        files
      end

      def generate_pages_in_parallel(markdown_files, progress, mutex)
        Parallel.each(markdown_files, in_threads: Parallel.processor_count) do |file_path|
          generate_page(file_path, thread_local_renderer)
          mutex.synchronize { progress.advance }
        end
      end

      def generate_pages_sequentially(markdown_files, progress)
        renderer = build_renderer
        markdown_files.each do |file_path|
          generate_page(file_path, renderer)
          progress.advance
        end
      end

      def thread_local_renderer
        Thread.current[:docyard_build_renderer] ||= build_renderer
      end

      def build_renderer
        Renderer.new(base_url: config.build.base, config: config)
      end

      def generate_page(markdown_file_path, renderer)
        relative_path = markdown_file_path.delete_prefix("docs/")
        output_path = Utils::PathUtils.markdown_to_html_output(relative_path, config.build.output)
        current_path = Utils::PathUtils.markdown_file_to_url(markdown_file_path, "docs")

        html_content = render_markdown_file(markdown_file_path, current_path, renderer)
        html_content = apply_search_exclusion(html_content, current_path)
        write_output(output_path, html_content)
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
          docs_path: "docs",
          config: config,
          sidebar_cache: sidebar_cache
        )
      end

      def write_output(output_path, html_content)
        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, html_content)
        log "Generated: #{output_path}" if verbose
      end

      def build_sidebar_cache
        @sidebar_cache = Sidebar::Cache.new(
          docs_path: "docs",
          config: config
        )
        @sidebar_cache.build
      end

      def log(message)
        Docyard.logger.info(message) if verbose
      end

      def generate_error_page
        output_path = File.join(config.build.output, "404.html")

        html_content = if File.exist?("docs/404.html")
                         File.read("docs/404.html")
                       else
                         build_renderer.render_not_found
                       end

        File.write(output_path, html_content)
        log "[✓] Generated 404.html"
      end
    end
  end
end
