# frozen_string_literal: true

module Docyard
  module Sidebar
    class Item
      attr_reader :slug, :text, :icon, :link, :target, :collapsed, :items, :path, :active, :type

      def initialize(**options)
        @slug = options[:slug]
        @text = options[:text]
        @icon = options[:icon]
        @link = options[:link]
        @target = options[:target] || "_self"
        @collapsed = options[:collapsed] || false
        @items = options[:items] || []
        @path = options[:path] || options[:link]
        @active = options[:active] || false
        @type = options[:type] || :file
      end

      def external?
        return false if path.nil?

        path.start_with?("http://", "https://")
      end

      def children?
        items.any?
      end

      def title
        text
      end

      def children
        items
      end

      def collapsible?
        children?
      end

      def to_h
        {
          title: title,
          path: path,
          icon: icon,
          active: active,
          type: type,
          collapsed: collapsed,
          collapsible: collapsible?,
          target: target,
          children: children.map(&:to_h)
        }
      end
    end
  end
end
