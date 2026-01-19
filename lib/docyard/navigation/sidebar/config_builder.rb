# frozen_string_literal: true

require_relative "item"

module Docyard
  module Sidebar
    class ConfigBuilder
      attr_reader :config_items, :current_path, :start_depth

      def initialize(config_items, current_path: "/", start_depth: 1)
        @config_items = config_items || []
        @current_path = Utils::PathResolver.normalize(current_path)
        @start_depth = start_depth
      end

      def build
        parse_items(config_items, base_path: "", depth: start_depth).map(&:to_h)
      end

      private

      def parse_items(items, base_path:, depth:)
        items.map { |item| parse_item(item, base_path: base_path, depth: depth) }.compact
      end

      def parse_item(item_config, base_path:, depth:)
        case item_config
        when String
          build_page_item(item_config, base_path: base_path)
        when Hash
          parse_hash_item(item_config, base_path: base_path, depth: depth)
        end
      end

      def parse_hash_item(config, base_path:, depth:)
        return build_external_link(config) if external_link?(config)

        slug, options = extract_slug_and_options(config)
        return build_page_item(slug, base_path: base_path, options: options) if leaf_item?(options)

        build_group_item(slug, options: options, base_path: base_path, depth: depth)
      end

      def external_link?(config)
        config.key?("link") || config.key?(:link)
      end

      def extract_slug_and_options(config)
        if config.keys.first.is_a?(String) && !external_link?(config)
          [config.keys.first.to_s, config.values.first || {}]
        else
          [nil, config]
        end
      end

      def leaf_item?(options)
        return true if options.nil?
        return false if options.is_a?(Hash) && (options.key?("items") || options.key?(:items))

        true
      end

      def build_page_item(slug, base_path:, options: {})
        options = normalize_options(options)
        url_path = build_url_path(base_path, slug)

        Item.new(
          slug: slug,
          text: options[:text] || titleize_slug(slug),
          path: url_path,
          icon: options[:icon],
          badge: options[:badge],
          badge_type: options[:badge_type],
          active: current_path == url_path,
          type: :file,
          section: false,
          items: []
        )
      end

      def build_group_item(slug, options:, base_path:, depth:)
        options = normalize_options(options)
        context = build_group_context(slug, options, base_path, depth)
        children = parse_items(options[:items] || [], base_path: context[:new_base_path], depth: depth + 1)

        create_group_item(slug, options, context, children)
      end

      def build_group_context(slug, options, base_path, depth)
        is_section = section_at_depth?(options, depth)
        is_virtual_group = options[:group] == true
        has_index = options[:index] == true
        new_base_path = compute_new_base_path(slug, base_path, is_virtual_group)
        url_path = has_index && !is_section ? build_url_path(base_path, slug) : nil

        { is_section: is_section, has_index: has_index, new_base_path: new_base_path, url_path: url_path }
      end

      def compute_new_base_path(slug, base_path, is_virtual_group)
        return base_path if is_virtual_group
        return base_path unless slug

        File.join(base_path, slug)
      end

      def create_group_item(slug, options, context, children)
        Item.new(
          slug: slug,
          text: options[:text] || titleize_slug(slug),
          path: context[:url_path],
          icon: options[:icon],
          badge: options[:badge],
          badge_type: options[:badge_type],
          active: context[:has_index] && current_path == context[:url_path],
          type: :directory,
          section: context[:is_section],
          collapsed: determine_collapsed_state(context[:is_section], options, children),
          has_index: context[:has_index],
          items: children
        )
      end

      def build_external_link(config)
        config = normalize_options(config)
        url = config[:link]

        Item.new(
          slug: nil,
          text: config[:text],
          path: url,
          link: url,
          icon: config[:icon],
          target: config[:target] || "_blank",
          type: :external,
          section: false,
          items: []
        )
      end

      def section_at_depth?(options, depth)
        return false if options[:collapsible] == true
        return false if options[:group] == true

        depth == 1
      end

      def determine_collapsed_state(is_section, options, children)
        return false if is_section
        return false if child_active?(children)
        return options[:collapsed] if options.key?(:collapsed)

        true
      end

      def child_active?(children)
        children.any? { |child| child.active || child_active?(child.items) }
      end

      def build_url_path(base_path, slug)
        base_path = base_path.to_s.sub(%r{^/+}, "")
        return base_path.empty? ? "/" : "/#{base_path}" if slug == "index"

        path = [base_path, slug].reject(&:empty?).join("/")
        "/#{path}"
      end

      def titleize_slug(slug)
        Utils::TextFormatter.titleize(slug.to_s)
      end

      def normalize_options(options)
        return {} if options.nil?
        return options if options.is_a?(Hash) && options.keys.all? { |k| k.is_a?(Symbol) }

        options.transform_keys(&:to_sym)
      end
    end
  end
end
