# frozen_string_literal: true

require "fileutils"
require "yaml"
require "parallel"
require "vips"
require_relative "social_cards/card_renderer"
require_relative "social_cards/homepage_card"
require_relative "social_cards/doc_card"

module Docyard
  module Build
    class SocialCardsGenerator
      OUTPUT_DIR = "_docyard/og"
      FRONTMATTER_REGEX = /\A---\s*\n(.*?\n)---\s*\n/m
      HOMEPAGE_PATHS = ["/", "/index"].freeze
      PARALLEL_THRESHOLD = 5

      attr_reader :config, :verbose

      def initialize(config, verbose: false)
        @config = config
        @verbose = verbose
        @generated_cards = []
        @failed_cards = []
      end

      def generate
        pages = collect_pages
        generate_cards_for(pages)
        [successful_count, build_verbose_details]
      end

      def successful_count
        @generated_cards.compact.size
      end

      def card_path_for(url_path)
        File.join("/", OUTPUT_DIR, url_to_filename(url_path))
      end

      private

      def generate_cards_for(pages)
        if pages.size >= PARALLEL_THRESHOLD
          results = Parallel.map(pages, in_threads: Parallel.processor_count) do |page|
            generate_card(page)
          end
          @generated_cards = results.compact
        else
          pages.each { |page| @generated_cards << generate_card(page) }
        end
      end

      def collect_pages
        pages = []

        Dir.glob(File.join(docs_path, "**", "*.md")).each do |file_path|
          frontmatter = extract_frontmatter(file_path)
          relative_path = file_path.delete_prefix("#{docs_path}/")
          url_path = markdown_to_url(relative_path)

          pages << build_page_data(file_path, url_path, frontmatter)
        end

        pages
      end

      def build_page_data(file_path, url_path, frontmatter)
        social_cards_config = frontmatter["social_cards"] || {}
        section = derive_section(url_path)

        {
          file_path: file_path,
          url_path: url_path,
          title: resolve_title(social_cards_config, frontmatter, url_path),
          description: social_cards_config["description"] || frontmatter["description"],
          section: section,
          is_homepage: homepage?(url_path)
        }
      end

      def resolve_title(social_cards_config, frontmatter, url_path)
        title = social_cards_config["title"]
        return title if title && !title.strip.empty?

        title = frontmatter["title"]
        return title if title && !title.strip.empty?

        derive_title_from_path(url_path)
      end

      def generate_card(page)
        output_path = File.join(config.build.output, OUTPUT_DIR, url_to_filename(page[:url_path]))
        card = build_card_for(page)
        card.render(output_path)
        output_path
      rescue Vips::Error => e
        log_card_error(page, "Vips rendering failed: #{e.message}")
        nil
      rescue StandardError => e
        log_card_error(page, e.message)
        nil
      end

      def log_card_error(page, message)
        @failed_cards << page[:url_path]
        Docyard.logger.warn("Social card generation failed for #{page[:url_path]}: #{message}")
      end

      def build_card_for(page)
        if page[:is_homepage]
          SocialCards::HomepageCard.new(config, title: page[:title])
        else
          SocialCards::DocCard.new(
            config,
            title: page[:title],
            section: page[:section],
            description: page[:description]
          )
        end
      end

      def extract_frontmatter(file_path)
        content = File.read(file_path)
        match = content.match(FRONTMATTER_REGEX)
        return {} unless match

        YAML.safe_load(match[1]) || {}
      rescue Psych::SyntaxError
        {}
      end

      def markdown_to_url(relative_path)
        path = relative_path
          .delete_suffix(".md")
          .delete_suffix("/index")

        path = "index" if path == "index" || path.empty?
        "/#{path}"
      end

      def url_to_filename(url_path)
        path = url_path.delete_prefix("/")
        path = "index" if path.empty?
        "#{path}.png"
      end

      def homepage?(url_path)
        HOMEPAGE_PATHS.include?(url_path)
      end

      def derive_section(url_path)
        parts = url_path.delete_prefix("/").split("/")
        return nil if parts.size <= 1

        parts.first.tr("-", " ").split.map(&:capitalize).join(" ")
      end

      def derive_title_from_path(url_path)
        filename = File.basename(url_path)
        filename = "Home" if filename == "index" || filename.empty?
        filename.tr("-", " ").split.map(&:capitalize).join(" ")
      end

      def docs_path
        config.source
      end

      def build_verbose_details
        return nil unless verbose

        details = @generated_cards.compact.map do |path|
          path.delete_prefix("#{config.build.output}/")
        end

        @failed_cards.each do |url_path|
          details << "FAILED: #{url_path}"
        end

        details
      end
    end
  end
end
