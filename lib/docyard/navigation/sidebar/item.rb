# frozen_string_literal: true

module Docyard
  module Sidebar
    class Item
      attr_reader :slug, :text, :icon, :link, :target, :collapsed, :items, :path, :active, :type, :has_index, :section

      DEFAULTS = {
        target: "_self",
        collapsed: false,
        items: [],
        active: false,
        type: :file,
        has_index: false,
        section: true
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
        assign_navigation_attributes(options)
        assign_state_attributes(options)
      end

      def assign_navigation_attributes(options)
        @target = options.fetch(:target, DEFAULTS[:target])
        @path = options[:path] || options[:link]
        @active = options.fetch(:active, DEFAULTS[:active])
        @type = options.fetch(:type, DEFAULTS[:type])
      end

      def assign_state_attributes(options)
        @collapsed = options.fetch(:collapsed, DEFAULTS[:collapsed])
        @items = options.fetch(:items, DEFAULTS[:items])
        @has_index = options.fetch(:has_index, DEFAULTS[:has_index])
        @section = options.fetch(:section, DEFAULTS[:section])
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
        children? && !section
      end

      def section?
        section == true
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
          section: section,
          children: children.map(&:to_h)
        }
      end
    end
  end
end
