# frozen_string_literal: true

require "tty-progressbar"

module Docyard
  module Build
    class StaticGenerator
      attr_reader :config, :verbose, :renderer

      def initialize(config, verbose: false)
        @config = config
        @verbose = verbose
        @renderer = Renderer.new(base_url: config.build.base_url)
      end

      def generate
        markdown_files = collect_markdown_files
        puts "\n[✓] Found #{markdown_files.size} markdown files"

        progress = TTY::ProgressBar.new(
          "Generating pages [:bar] :current/:total (:percent%)",
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

      def collect_markdown_files
        Dir.glob(File.join("docs", "**", "*.md"))
      end

      def generate_page(markdown_file_path)
        output_path = determine_output_path(markdown_file_path)
        current_path = determine_current_path(markdown_file_path)

        sidebar_html = build_sidebar(current_path)
        html_content = renderer.render_file(
          markdown_file_path,
          sidebar_html: sidebar_html,
          branding: branding_options
        )

        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, html_content)

        log "Generated: #{output_path}" if verbose
      end

      def determine_output_path(markdown_file_path)
        relative_path = markdown_file_path.delete_prefix("docs/")
        base_name = File.basename(relative_path, ".md")
        dir_name = File.dirname(relative_path)

        output_dir = config.build.output_dir

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

      def build_sidebar(current_path)
        SidebarBuilder.new(
          docs_path: "docs",
          current_path: current_path,
          config: config
        ).to_html
      end

      def branding_options
        default_branding.merge(config_branding_options)
      end

      def default_branding
        {
          site_title: Constants::DEFAULT_SITE_TITLE,
          site_description: "",
          logo: Constants::DEFAULT_LOGO_PATH,
          logo_dark: Constants::DEFAULT_LOGO_DARK_PATH,
          favicon: nil,
          display_logo: true,
          display_title: true
        }
      end

      def config_branding_options
        site = config.site
        branding = config.branding

        {
          site_title: site.title || Constants::DEFAULT_SITE_TITLE,
          site_description: site.description || "",
          logo: resolve_logo(branding.logo, branding.logo_dark),
          logo_dark: resolve_logo_dark(branding.logo, branding.logo_dark),
          favicon: branding.favicon
        }.merge(appearance_options(branding.appearance))
      end

      def appearance_options(appearance)
        appearance ||= {}
        {
          display_logo: appearance["logo"] != false,
          display_title: appearance["title"] != false
        }
      end

      def resolve_logo(logo, logo_dark)
        logo || logo_dark || Constants::DEFAULT_LOGO_PATH
      end

      def resolve_logo_dark(logo, logo_dark)
        logo_dark || logo || Constants::DEFAULT_LOGO_DARK_PATH
      end

      def log(message)
        puts message if verbose
      end
    end
  end
end
