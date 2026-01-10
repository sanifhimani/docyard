# frozen_string_literal: true

require "tty-progressbar"
require_relative "../rendering/template_resolver"
require_relative "../navigation/prev_next_builder"

module Docyard
  module Build
    class StaticGenerator
      attr_reader :config, :verbose, :renderer

      def initialize(config, verbose: false)
        @config = config
        @verbose = verbose
        @renderer = Renderer.new(base_url: config.build.base, config: config)
      end

      def generate
        copy_custom_landing_page if custom_landing_page?

        markdown_files = collect_markdown_files
        puts "\n[✓] Found #{markdown_files.size} markdown files"

        progress = TTY::ProgressBar.new(
          "Generating pages [:bar] :current/:total (:percent)",
          total: markdown_files.size,
          width: 50
        )

        markdown_files.each do |file_path|
          generate_page(file_path)
          progress.advance
        end

        markdown_files.size
      end

      private

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

      def generate_page(markdown_file_path)
        output_path = determine_output_path(markdown_file_path)
        current_path = determine_current_path(markdown_file_path)

        html_content = render_markdown_file(markdown_file_path, current_path)
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

      def render_markdown_file(markdown_file_path, current_path)
        markdown = Markdown.new(File.read(markdown_file_path))
        template_resolver = TemplateResolver.new(markdown.frontmatter, config.data)

        sidebar_builder = build_sidebar_instance(current_path)
        sidebar_html = template_resolver.show_sidebar? ? sidebar_builder.to_html : ""
        prev_next_html = template_resolver.show_sidebar? ? build_prev_next(sidebar_builder, current_path, markdown) : ""

        renderer.render_file(
          markdown_file_path,
          sidebar_html: sidebar_html,
          prev_next_html: prev_next_html,
          branding: branding_options,
          template_options: template_resolver.to_options
        )
      end

      def write_output(output_path, html_content)
        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, html_content)
        log "Generated: #{output_path}" if verbose
      end

      def determine_output_path(markdown_file_path)
        relative_path = markdown_file_path.delete_prefix("docs/")
        base_name = File.basename(relative_path, ".md")
        dir_name = File.dirname(relative_path)

        output_dir = config.build.output

        if base_name == "index"
          File.join(output_dir, dir_name, "index.html")
        else
          File.join(output_dir, dir_name, base_name, "index.html")
        end
      end

      def determine_current_path(markdown_file_path)
        relative_path = markdown_file_path.delete_prefix("docs/")
        base_name = File.basename(relative_path, ".md")
        dir_name = File.dirname(relative_path)

        if base_name == "index"
          dir_name == "." ? "/" : "/#{dir_name}"
        else
          dir_name == "." ? "/#{base_name}" : "/#{dir_name}/#{base_name}"
        end
      end

      def build_sidebar_instance(current_path)
        SidebarBuilder.new(
          docs_path: "docs",
          current_path: current_path,
          config: config
        )
      end

      def build_prev_next(sidebar_builder, current_path, markdown)
        PrevNextBuilder.new(
          sidebar_tree: sidebar_builder.tree,
          current_path: current_path,
          frontmatter: markdown.frontmatter,
          config: {}
        ).to_html
      end

      def branding_options
        BrandingResolver.new(config).resolve
      end

      def log(message)
        puts message if verbose
      end
    end
  end
end
