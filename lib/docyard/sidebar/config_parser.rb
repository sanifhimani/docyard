# frozen_string_literal: true

require_relative "item"
require_relative "title_extractor"

module Docyard
  module Sidebar
    class ConfigParser
      attr_reader :config_items, :docs_path, :current_path, :title_extractor

      def initialize(config_items, docs_path:, current_path: "/", title_extractor: TitleExtractor.new)
        @config_items = config_items || []
        @docs_path = docs_path
        @current_path = Utils::PathResolver.normalize(current_path)
        @title_extractor = title_extractor
      end

      def parse
        parse_items(config_items)
      end

      private

      def parse_items(items, base_path = "")
        items.map do |item_config|
          parse_item(item_config, base_path)
        end.compact
      end

      def parse_item(item_config, base_path)
        case item_config
        when String
          resolve_file_item(item_config, base_path)
        when Hash
          parse_hash_item(item_config, base_path)
        end
      end

      def parse_hash_item(item_config, base_path)
        return parse_link_item(item_config) if link_item?(item_config)
        return parse_nested_item(item_config, base_path) if nested_item?(item_config)
        return resolve_file_item(item_config.keys.first, base_path, {}) if nil_value_item?(item_config)

        slug = item_config.keys.first
        options = item_config.values.first || {}
        resolve_file_item(slug, base_path, options)
      end

      def link_item?(config)
        config.key?("link") || config.key?(:link)
      end

      def nested_item?(config)
        config.size == 1 && config.values.first.is_a?(Hash)
      end

      def nil_value_item?(config)
        config.size == 1 && config.values.first.nil?
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

      def parse_nested_item(item_config, base_path)
        slug = item_config.keys.first.to_s
        options = item_config.values.first || {}
        nested_items = extract_nested_items(options)

        dir_path = File.join(docs_path, base_path, slug)

        if File.directory?(dir_path)
          build_directory_item(slug, options, nested_items, base_path)
        elsif nested_items.any?
          build_file_with_children_item(slug, options, nested_items, base_path)
        else
          resolve_file_item(slug, base_path, options)
        end
      end

      def extract_nested_items(options)
        options["items"] || options[:items] || []
      end

      def extract_common_options(options)
        {
          text: options["text"] || options[:text],
          icon: options["icon"] || options[:icon],
          collapsed: options["collapsed"] || options[:collapsed] || false
        }
      end

      def build_directory_item(slug, options, nested_items, base_path)
        common_opts = extract_common_options(options)
        new_base_path = File.join(base_path, slug)
        parsed_items = parse_items(nested_items, new_base_path)

        Item.new(
          slug: slug,
          text: common_opts[:text] || Utils::TextFormatter.titleize(slug),
          icon: common_opts[:icon],
          collapsed: common_opts[:collapsed],
          items: parsed_items,
          type: :directory
        )
      end

      def build_file_with_children_item(slug, options, nested_items, base_path)
        common_opts = extract_common_options(options)
        file_path = File.join(docs_path, base_path, "#{slug}.md")
        url_path = Utils::PathResolver.to_url(File.join(base_path, slug))
        resolved_text = common_opts[:text] || extract_file_title(file_path, slug)

        Item.new(
          slug: slug,
          text: resolved_text,
          path: url_path,
          icon: common_opts[:icon],
          collapsed: common_opts[:collapsed],
          items: parse_items(nested_items, base_path),
          active: current_path == url_path,
          type: :file
        )
      end

      def extract_file_title(file_path, slug)
        File.exist?(file_path) ? title_extractor.extract(file_path) : Utils::TextFormatter.titleize(slug)
      end

      def resolve_file_item(slug, base_path, options = {})
        slug_str = slug.to_s
        options ||= {}

        file_path = File.join(docs_path, base_path, "#{slug_str}.md")
        url_path = Utils::PathResolver.to_url(File.join(base_path, slug_str))

        frontmatter = extract_frontmatter_metadata(file_path)
        text = resolve_item_text(slug_str, file_path, options, frontmatter[:text])
        icon = resolve_item_icon(options, frontmatter[:icon])
        final_path = options["link"] || options[:link] || url_path

        Item.new(
          slug: slug_str, text: text, path: final_path, icon: icon,
          active: current_path == final_path, type: :file
        )
      end

      def extract_frontmatter_metadata(file_path)
        return { text: nil, icon: nil } unless File.exist?(file_path)

        markdown = Markdown.new(File.read(file_path))
        {
          text: markdown.sidebar_text || markdown.title,
          icon: markdown.sidebar_icon
        }
      end

      def resolve_item_text(slug, file_path, options, frontmatter_text)
        text = options["text"] || options[:text] || frontmatter_text
        text || extract_file_title(file_path, slug)
      end

      def resolve_item_icon(options, frontmatter_icon)
        options["icon"] || options[:icon] || frontmatter_icon
      end
    end
  end
end
