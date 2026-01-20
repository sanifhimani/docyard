# frozen_string_literal: true

require_relative "item"
require_relative "local_config_loader"
require_relative "config_builder"

module Docyard
  module Sidebar
    class DistributedBuilder
      attr_reader :docs_path, :current_path

      def initialize(docs_path, current_path: "/")
        @docs_path = docs_path
        @current_path = Utils::PathResolver.normalize(current_path)
      end

      def build
        root_config = load_root_config
        return [] if root_config.empty?

        root_config.map { |section_slug| build_section(section_slug) }
      end

      private

      def load_root_config
        loader = LocalConfigLoader.new(docs_path)
        config = loader.load
        raise_missing_root_config unless config

        normalize_root_config(config)
      end

      def normalize_root_config(config)
        config.map do |item|
          case item
          when String then item
          when Hash then item.keys.first.to_s
          end
        end.compact
      end

      def build_section(section_slug)
        section_path = File.join(docs_path, section_slug)
        section_config = load_section_config(section_slug, section_path)

        build_section_item(section_slug, section_config)
      end

      def load_section_config(section_slug, section_path)
        loader = LocalConfigLoader.new(section_path)
        raise_missing_section_config(section_slug) unless loader.config_file_exists?

        raw_config = YAML.load_file(File.join(section_path, "_sidebar.yml"))
        normalize_section_config(raw_config)
      end

      def normalize_section_config(config)
        return { items: config } if config.is_a?(Array)

        config.transform_keys(&:to_sym)
      end

      def build_section_item(section_slug, section_config)
        items = section_config[:items] || []
        children = build_section_children(items, section_slug)

        Item.new(
          slug: section_slug,
          text: section_config[:text] || Utils::TextFormatter.titleize(section_slug),
          path: nil,
          icon: section_config[:icon],
          type: :directory,
          section: true,
          collapsed: false,
          has_index: false,
          active: false,
          items: children
        ).to_h
      end

      def build_section_children(items, section_slug)
        adjusted_current_path = adjust_current_path_for_section(section_slug)

        builder = ConfigBuilder.new(items, current_path: adjusted_current_path, start_depth: 2)
        tree = builder.build

        prefix_paths(tree, section_slug)
      end

      def adjust_current_path_for_section(section_slug)
        prefix = "/#{section_slug}"
        return current_path unless current_path.start_with?(prefix)

        relative = current_path.sub(prefix, "")
        relative.empty? ? "/" : relative
      end

      def prefix_paths(items, prefix)
        items.map do |item|
          prefixed = prefix_item_path(item, prefix)
          prefixed[:children] = prefix_paths(item[:children] || [], prefix) if item[:children]&.any?
          prefixed
        end
      end

      def prefix_item_path(item, prefix)
        item = item.dup
        return item if item[:path].nil? || external_path?(item[:path])

        prefixed_path = "/#{prefix}#{item[:path]}"
        item[:path] = prefixed_path.chomp("/")
        item[:path] = "/" if item[:path].empty?
        item[:active] = current_path == item[:path]
        item
      end

      def external_path?(path)
        path.start_with?("http://", "https://")
      end

      def raise_missing_root_config
        raise SidebarConfigError, <<~MSG.strip
          Distributed sidebar mode requires docs/_sidebar.yml

          Either:
            1. Create docs/_sidebar.yml listing your sections
            2. Change to 'sidebar: config' in docyard.yml
        MSG
      end

      def raise_missing_section_config(section_slug)
        raise SidebarConfigError, <<~MSG.strip
          Missing sidebar config for section '#{section_slug}'

          Expected: docs/#{section_slug}/_sidebar.yml

          Either:
            1. Create docs/#{section_slug}/_sidebar.yml
            2. Remove '#{section_slug}' from docs/_sidebar.yml
        MSG
      end
    end
  end
end
