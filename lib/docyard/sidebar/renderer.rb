# frozen_string_literal: true

require "erb"

module Docyard
  module Sidebar
    class Renderer
      PARTIALS_PATH = File.join(__dir__, "../templates/partials")

      attr_reader :site_title

      def initialize(site_title: "Documentation")
        @site_title = site_title
      end

      def render(tree)
        return "" if tree.empty?

        nav_content = render_tree_with_sections(tree)
        footer_html = render_partial(:sidebar_footer)

        render_partial(:sidebar, nav_content: nav_content, footer_html: footer_html)
      end

      private

      def render_partial(name, locals = {})
        template_path = File.join(PARTIALS_PATH, "_#{name}.html.erb")
        template = File.read(template_path)

        locals.each { |key, value| instance_variable_set("@#{key}", value) }

        erb_binding = binding
        ERB.new(template).result(erb_binding)
      end

      def icon(name)
        render_partial(:icons, icon_name: name)
      end

      def render_tree_with_sections(items)
        filtered_items = items.reject { |item| item[:title]&.downcase == site_title.downcase }
        grouped_items = group_by_section(filtered_items)

        grouped_items.map do |section_name, section_items|
          render_section(section_name, section_items)
        end.join
      end

      def render_section(section_name, section_items)
        section_content = render_tree(section_items)
        render_partial(:nav_section, section_name: section_name, section_content: section_content)
      end

      def group_by_section(items)
        sections = {}
        root_items = []

        items.each do |item|
          process_section_item(item, sections, root_items)
        end

        build_section_result(sections, root_items)
      end

      def process_section_item(item, sections, root_items)
        return if item[:title]&.downcase == site_title.downcase

        if item[:type] == :directory && !item[:children].empty?
          section_name = item[:title].upcase
          sections[section_name] = item[:children]
        else
          root_items << item
        end
      end

      def build_section_result(sections, root_items)
        result = {}
        result[nil] = root_items unless root_items.empty?
        result.merge!(sections)
      end

      def render_tree(items)
        return "" if items.empty?

        list_items = items.map { |item| render_item(item) }.join
        render_partial(:nav_list, list_items: list_items)
      end

      def render_item(item)
        item_content = if item[:children].empty?
                         render_leaf_item(item)
                       else
                         render_group_item(item)
                       end

        render_partial(:nav_item, item_content: item_content)
      end

      def render_leaf_item(item)
        render_partial(:nav_leaf, path: item[:path], title: item[:title], active: item[:active])
      end

      def render_group_item(item)
        children_html = render_tree(item[:children])
        render_partial(:nav_group, title: item[:title], children_html: children_html)
      end
    end
  end
end
