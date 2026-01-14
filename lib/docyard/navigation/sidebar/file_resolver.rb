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
          type: :external,
          section: false
        )
      end

      def build_file_with_children(slug:, options:, base_path:, parsed_items:, depth: 1)
        common_opts = metadata_extractor.extract_common_options(options)
        file_path = File.join(docs_path, base_path, "#{slug}.md")
        url_path = Utils::PathResolver.to_url(File.join(base_path, slug))
        is_section = section_for_depth?(common_opts[:section], depth)

        Item.new(
          slug: slug,
          text: common_opts[:text] || metadata_extractor.extract_file_title(file_path, slug),
          path: is_section ? nil : url_path,
          icon: common_opts[:icon],
          collapsed: is_section ? false : common_opts[:collapsed],
          items: parsed_items,
          active: is_section ? false : current_path == url_path,
          type: is_section ? :section : :file,
          section: is_section
        )
      end

      private

      def section_for_depth?(explicit_section, depth)
        return explicit_section unless explicit_section.nil?

        depth == 1
      end

      def build_context(slug, base_path, options)
        paths = resolve_paths(slug, base_path, options)
        frontmatter = metadata_extractor.extract_frontmatter_metadata(paths[:file])

        build_context_hash(slug, paths, options, frontmatter)
      end

      def resolve_paths(slug, base_path, options)
        file_path = File.join(docs_path, base_path, "#{slug}.md")
        url_path = Utils::PathResolver.to_url(File.join(base_path, slug))
        final_path = options["link"] || options[:link] || url_path

        { file: file_path, final: final_path }
      end

      def build_context_hash(slug, paths, options, frontmatter)
        {
          slug: slug,
          text: metadata_extractor.resolve_item_text(slug, paths[:file], options, frontmatter[:text]),
          path: paths[:final],
          icon: metadata_extractor.resolve_item_icon(options, frontmatter[:icon]),
          badge: frontmatter[:badge],
          badge_type: frontmatter[:badge_type],
          active: current_path == paths[:final],
          type: :file,
          section: false
        }
      end
    end
  end
end
