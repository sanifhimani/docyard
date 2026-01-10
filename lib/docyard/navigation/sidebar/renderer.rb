# frozen_string_literal: true

require "erb"
require_relative "../../rendering/icon_helpers"

module Docyard
  module Sidebar
    class Renderer
      include Utils::UrlHelpers
      include IconHelpers

      PARTIALS_PATH = File.join(__dir__, "../../templates/partials")

      attr_reader :site_title, :base_url

      def initialize(site_title: "Documentation", base_url: "/")
        @site_title = site_title
        @base_url = normalize_base_url(base_url)
      end

      def render(tree)
        return "" if tree.empty?

        nav_content = render_tree_with_sections(tree)
        render_partial(:sidebar, nav_content: nav_content)
      end

      private

      def render_partial(name, locals = {})
        template_path = File.join(PARTIALS_PATH, "_#{name}.html.erb")
        template = File.read(template_path)

        locals.each { |key, value| instance_variable_set("@#{key}", value) }

        erb_binding = binding
        ERB.new(template).result(erb_binding)
      end

      def render_tree_with_sections(items)
        filtered_items = items.reject { |item| item[:title]&.downcase == site_title.downcase }
        grouped = group_items_by_section(filtered_items)

        grouped.map do |group|
          if group[:section]
            render_section(group[:item])
          else
            render_item_group(group[:items])
          end
        end.join
      end

      def group_items_by_section(items)
        groups = []
        current_non_section_items = []

        items.each do |item|
          if item[:section]
            if current_non_section_items.any?
              groups << { section: false, items: current_non_section_items }
              current_non_section_items = []
            end
            groups << { section: true, item: item }
          else
            current_non_section_items << item
          end
        end

        groups << { section: false, items: current_non_section_items } if current_non_section_items.any?
        groups
      end

      def render_section(item)
        section_content = render_tree(item[:children])
        render_partial(:nav_section,
                       section_name: item[:title],
                       section_icon: item[:icon],
                       section_content: section_content)
      end

      def render_item_group(items)
        render_partial(:nav_section,
                       section_name: nil,
                       section_icon: nil,
                       section_content: render_tree(items))
      end

      def render_tree(items)
        return "" if items.empty?

        list_items = items.map { |item| render_item(item) }.join
        render_partial(:nav_list, list_items: list_items)
      end

      def render_item(item)
        item_content = if item[:children].empty?
                         render_leaf_item(item)
                       elsif item[:section]
                         render_nested_section(item)
                       else
                         render_group_item(item)
                       end

        render_partial(:nav_item, item_content: item_content)
      end

      def render_leaf_item(item)
        render_partial(
          :nav_leaf,
          path: item[:path],
          title: item[:title],
          active: item[:active],
          icon: item[:icon],
          target: item[:target]
        )
      end

      def render_nested_section(item)
        children_html = render_tree(item[:children])
        render_partial(
          :nav_nested_section,
          title: item[:title],
          icon: item[:icon],
          children_html: children_html
        )
      end

      def render_group_item(item)
        children_html = render_tree(item[:children])
        render_partial(
          :nav_group,
          title: item[:title],
          path: item[:path],
          active: item[:active],
          children_html: children_html,
          icon: item[:icon],
          collapsed: item[:collapsed],
          has_index: item[:has_index]
        )
      end
    end
  end
end
