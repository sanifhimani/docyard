# frozen_string_literal: true

require_relative "item"
require_relative "title_extractor"
require_relative "metadata_extractor"
require_relative "children_discoverer"
require_relative "file_resolver"

module Docyard
  module Sidebar
    class ConfigParser
      attr_reader :config_items, :docs_path, :current_path, :metadata_extractor,
                  :children_discoverer, :file_resolver

      def initialize(config_items, docs_path:, current_path: "/", title_extractor: TitleExtractor.new)
        @config_items = config_items || []
        @docs_path = docs_path
        @current_path = Utils::PathResolver.normalize(current_path)
        @metadata_extractor = MetadataExtractor.new(docs_path: docs_path, title_extractor: title_extractor)
        @children_discoverer = ChildrenDiscoverer.new(docs_path: docs_path)
        @file_resolver = FileResolver.new(
          docs_path: docs_path, current_path: @current_path, metadata_extractor: metadata_extractor
        )
      end

      def parse
        parse_items(config_items, "", depth: 1)
      end

      private

      def parse_items(items, base_path, depth:)
        items.map { |item_config| parse_item(item_config, base_path, depth: depth) }.compact
      end

      def parse_item(item_config, base_path, depth:)
        case item_config
        when String then resolve_string_item(item_config, base_path, depth: depth)
        when Hash then parse_hash_item(item_config, base_path, depth: depth)
        end
      end

      def resolve_string_item(slug, base_path, depth:)
        if File.directory?(File.join(docs_path, base_path, slug))
          build_directory_item(slug, {}, [], base_path, depth: depth)
        else
          file_resolver.resolve(slug, base_path)
        end
      end

      def parse_hash_item(item_config, base_path, depth:)
        return file_resolver.build_link_item(item_config) if external_link?(item_config)

        slug = item_config.keys.first
        options = item_config.values.first

        return file_resolver.resolve(slug, base_path, {}) if options.nil?
        return parse_nested_item(slug, options, base_path, depth: depth) if options.is_a?(Hash)

        file_resolver.resolve(slug, base_path, options)
      end

      def external_link?(config)
        config.key?("link") || config.key?(:link)
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
          file_resolver.resolve(slug, base_path, options)
        end
      end

      def build_directory_item(slug, options, nested_items, base_path, depth:)
        context = build_directory_context(slug, options, nested_items, base_path, depth)
        context[:parsed_items] = prepend_intro_if_needed(context, depth)
        create_directory_item(slug, context, depth)
      end

      def build_directory_context(slug, options, nested_items, base_path, depth)
        new_base_path = File.join(base_path, slug)
        {
          common_opts: metadata_extractor.extract_common_options(options),
          parsed_items: resolve_directory_children(nested_items, new_base_path, depth),
          **build_index_info(new_base_path)
        }
      end

      def build_index_info(base_path)
        index_file_path = File.join(docs_path, base_path, "index.md")
        has_index = File.file?(index_file_path)
        url_path = has_index ? Utils::PathResolver.to_url(base_path) : nil

        { index_file_path: index_file_path, has_index: has_index,
          url_path: url_path, is_active: has_index && current_path == url_path }
      end

      def resolve_directory_children(nested_items, base_path, depth)
        return parse_items(nested_items, base_path, depth: depth + 1) if nested_items.any?

        auto_discover_children(base_path, depth: depth + 1)
      end

      def prepend_intro_if_needed(context, depth)
        is_section = section_for_depth?(context[:common_opts][:section], depth)
        return context[:parsed_items] unless is_section && context[:has_index]

        [build_introduction_item(context[:index_file_path], context[:url_path])] + context[:parsed_items]
      end

      def create_directory_item(slug, context, depth)
        is_section = section_for_depth?(context[:common_opts][:section], depth)
        Item.new(
          slug: slug,
          text: context[:common_opts][:text] || Utils::TextFormatter.titleize(slug),
          path: is_section ? nil : context[:url_path],
          icon: context[:common_opts][:icon],
          collapsed: is_section ? false : directory_collapsed?(context),
          active: is_section ? false : context[:is_active],
          has_index: is_section ? false : context[:has_index],
          items: context[:parsed_items],
          type: :directory,
          section: is_section
        )
      end

      def section_for_depth?(explicit_section, depth)
        return explicit_section unless explicit_section.nil?

        depth == 1
      end

      def directory_collapsed?(context)
        return false if context[:is_active] || active_child?(context[:parsed_items])

        context[:common_opts][:collapsed] != false
      end

      def build_introduction_item(index_file_path, url_path)
        metadata = metadata_extractor.extract_index_metadata(index_file_path)
        Item.new(
          slug: "index", text: metadata[:sidebar_text] || "Overview",
          path: url_path, icon: metadata[:icon], active: current_path == url_path, type: :file
        )
      end

      def build_file_with_children_item(slug, options, nested_items, base_path, depth:)
        file_resolver.build_file_with_children(
          slug: slug, options: options, base_path: base_path,
          parsed_items: parse_items(nested_items, base_path, depth: depth + 1),
          depth: depth
        )
      end

      def auto_discover_children(relative_path, depth:)
        children_discoverer.discover(relative_path, depth: depth) do |config_or_type, *args|
          if config_or_type.is_a?(Array)
            parse_items(config_or_type, args[0], depth: args[1])
          else
            build_discovered_item(config_or_type, args[0], args[1], depth)
          end
        end
      end

      def build_discovered_item(type, slug, base_path, depth)
        if type == :directory
          build_directory_item(slug, {}, [], base_path, depth: depth)
        else
          file_resolver.resolve(slug, base_path)
        end
      end

      def active_child?(items)
        items.any? { |item| item.active || active_child?(item.items) }
      end
    end
  end
end
