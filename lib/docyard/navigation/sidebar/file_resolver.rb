# frozen_string_literal: true

require_relative "item"

module Docyard
  module Sidebar
    class FileResolver
      attr_reader :docs_path, :current_path, :metadata_extractor

      def initialize(docs_path:, current_path:, metadata_extractor:)
        @docs_path = docs_path
        @current_path = current_path
        @metadata_extractor = metadata_extractor
      end

      def resolve(slug, base_path, options = {})
        context = build_context(slug.to_s, base_path, options || {})
        Item.new(**context)
      end

      def build_link_item(config)
        Item.new(
          text: config["text"] || config[:text],
          link: config["link"] || config[:link],
          path: config["link"] || config[:link],
          icon: config["icon"] || config[:icon],
          target: config["target"] || config[:target] || "_blank",
          type: :external
        )
      end

      def build_file_with_children(slug:, options:, base_path:, parsed_items:)
        common_opts = metadata_extractor.extract_common_options(options)
        file_path = File.join(docs_path, base_path, "#{slug}.md")
        url_path = Utils::PathResolver.to_url(File.join(base_path, slug))

        Item.new(
          slug: slug,
          text: common_opts[:text] || metadata_extractor.extract_file_title(file_path, slug),
          path: url_path,
          icon: common_opts[:icon],
          collapsed: common_opts[:collapsed],
          items: parsed_items,
          active: current_path == url_path,
          type: :file
        )
      end

      private

      def build_context(slug, base_path, options)
        file_path = File.join(docs_path, base_path, "#{slug}.md")
        url_path = Utils::PathResolver.to_url(File.join(base_path, slug))
        frontmatter = metadata_extractor.extract_frontmatter_metadata(file_path)
        final_path = options["link"] || options[:link] || url_path

        {
          slug: slug,
          text: metadata_extractor.resolve_item_text(slug, file_path, options, frontmatter[:text]),
          path: final_path,
          icon: metadata_extractor.resolve_item_icon(options, frontmatter[:icon]),
          active: current_path == final_path,
          type: :file
        }
      end
    end
  end
end
