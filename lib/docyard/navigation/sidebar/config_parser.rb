# frozen_string_literal: true

require_relative "item"
require_relative "title_extractor"
require_relative "metadata_extractor"

module Docyard
  module Sidebar
    class ConfigParser
      attr_reader :config_items, :docs_path, :current_path, :metadata_extractor

      def initialize(config_items, docs_path:, current_path: "/", title_extractor: TitleExtractor.new)
        @config_items = config_items || []
        @docs_path = docs_path
        @current_path = Utils::PathResolver.normalize(current_path)
        @metadata_extractor = MetadataExtractor.new(docs_path: docs_path, title_extractor: title_extractor)
      end

      def parse
        parse_items(config_items, "", depth: 1)
      end

      private

      def parse_items(items, base_path, depth:)
        items.map do |item_config|
          parse_item(item_config, base_path, depth: depth)
        end.compact
      end

      def parse_item(item_config, base_path, depth:)
        case item_config
        when String
          resolve_file_item(item_config, base_path)
        when Hash
          parse_hash_item(item_config, base_path, depth: depth)
        end
      end

      def parse_hash_item(item_config, base_path, depth:)
        return parse_link_item(item_config) if item_config.key?("link") || item_config.key?(:link)

        slug = item_config.keys.first
        options = item_config.values.first

        return resolve_file_item(slug, base_path, {}) if options.nil?
        return parse_nested_item(slug, options, base_path, depth: depth) if options.is_a?(Hash)

        resolve_file_item(slug, base_path, options)
      end

      def parse_link_item(config)
        link = config["link"] || config[:link]
        text = config["text"] || config[:text]
        icon = config["icon"] || config[:icon]
        target = config["target"] || config[:target] || "_blank"

        Item.new(
          text: text,
          link: link,
          path: link,
          icon: icon,
          target: target,
          type: :external
        )
      end

      def parse_nested_item(slug, options, base_path, depth:)
        slug = slug.to_s
        nested_items = options["items"] || options[:items] || []
        dir_path = File.join(docs_path, base_path, slug)

        if File.directory?(dir_path)
          build_directory_item(slug, options, nested_items, base_path, depth: depth)
        elsif nested_items.any?
          build_file_with_children_item(slug, options, nested_items, base_path, depth: depth)
        else
          resolve_file_item(slug, base_path, options)
        end
      end

      def build_directory_item(slug, options, nested_items, base_path, depth:)
        context = build_directory_context(slug, options, nested_items, base_path, depth)
        context[:parsed_items] = prepend_intro_if_needed(context, depth)

        create_directory_item(slug, context, depth)
      end

      def build_directory_context(slug, options, nested_items, base_path, depth)
        new_base_path = File.join(base_path, slug)
        index_file_path = File.join(docs_path, new_base_path, "index.md")
        has_index = File.file?(index_file_path)
        url_path = has_index ? Utils::PathResolver.to_url(new_base_path) : nil

        {
          common_opts: metadata_extractor.extract_common_options(options),
          parsed_items: parse_items(nested_items, new_base_path, depth: depth + 1),
          index_file_path: index_file_path,
          has_index: has_index,
          url_path: url_path,
          is_active: has_index && current_path == url_path
        }
      end

      def prepend_intro_if_needed(context, depth)
        return context[:parsed_items] unless depth == 1 && context[:has_index]

        intro_item = build_introduction_item(context[:index_file_path], context[:url_path])
        [intro_item] + context[:parsed_items]
      end

      def create_directory_item(slug, context, depth)
        is_top_level = depth == 1
        Item.new(
          slug: slug,
          text: context[:common_opts][:text] || Utils::TextFormatter.titleize(slug),
          path: is_top_level ? nil : context[:url_path],
          icon: context[:common_opts][:icon],
          collapsed: directory_collapsed?(context),
          active: is_top_level ? false : context[:is_active],
          has_index: is_top_level ? false : context[:has_index],
          items: context[:parsed_items],
          type: :directory
        )
      end

      def directory_collapsed?(context)
        return false if context[:is_active] || active_child?(context[:parsed_items])

        context[:common_opts][:collapsed] != false
      end

      def build_introduction_item(index_file_path, url_path)
        metadata = metadata_extractor.extract_index_metadata(index_file_path)
        Item.new(
          slug: "index",
          text: metadata[:sidebar_text] || "Introduction",
          path: url_path,
          icon: metadata[:icon],
          active: current_path == url_path,
          type: :file
        )
      end

      def build_file_with_children_item(slug, options, nested_items, base_path, depth:)
        common_opts = metadata_extractor.extract_common_options(options)
        file_path = File.join(docs_path, base_path, "#{slug}.md")
        url_path = Utils::PathResolver.to_url(File.join(base_path, slug))
        resolved_text = common_opts[:text] || metadata_extractor.extract_file_title(file_path, slug)

        Item.new(
          slug: slug,
          text: resolved_text,
          path: url_path,
          icon: common_opts[:icon],
          collapsed: common_opts[:collapsed],
          items: parse_items(nested_items, base_path, depth: depth + 1),
          active: current_path == url_path,
          type: :file
        )
      end

      def resolve_file_item(slug, base_path, options = {})
        context = build_file_context(slug.to_s, base_path, options || {})
        Item.new(**context)
      end

      def build_file_context(slug, base_path, options)
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

      def active_child?(items)
        items.any? do |item|
          item.active || active_child?(item.items)
        end
      end
    end
  end
end
