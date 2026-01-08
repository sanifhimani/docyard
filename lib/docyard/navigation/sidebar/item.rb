# frozen_string_literal: true

module Docyard
  module Sidebar
    class Item
      attr_reader :slug, :text, :icon, :link, :target, :collapsed, :items, :path, :active, :type, :has_index

      DEFAULTS = {
        target: "_self",
        collapsed: false,
        items: [],
        active: false,
        type: :file,
        has_index: false
      }.freeze

      def initialize(**options)
        assign_required_attributes(options)
        assign_optional_attributes(options)
      end

      private

      def assign_required_attributes(options)
        @slug = options[:slug]
        @text = options[:text]
        @icon = options[:icon]
        @link = options[:link]
      end

      def assign_optional_attributes(options)
        @target = options.fetch(:target, DEFAULTS[:target])
        @collapsed = options.fetch(:collapsed, DEFAULTS[:collapsed])
        @items = options.fetch(:items, DEFAULTS[:items])
        @path = options[:path] || options[:link]
        @active = options.fetch(:active, DEFAULTS[:active])
        @type = options.fetch(:type, DEFAULTS[:type])
        @has_index = options.fetch(:has_index, DEFAULTS[:has_index])
      end

      public

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
          has_index: has_index,
          children: children.map(&:to_h)
        }
      end
    end
  end
end
