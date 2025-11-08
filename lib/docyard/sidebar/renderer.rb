# frozen_string_literal: true

module Docyard
  module Sidebar
    class Renderer
      attr_reader :site_title

      def initialize(site_title: "Documentation")
        @site_title = site_title
      end

      def render(tree)
        return "" if tree.empty?

        html = "<nav>\n"
        html += "  <a href=\"/\">#{site_title}</a>\n"
        html += render_tree(tree)
        html += "</nav>\n"
        html
      end

      private

      def render_tree(items)
        return "" if items.empty?

        html = "  <ul>\n"
        items.each { |item| html += render_item(item) }
        html += "  </ul>\n"
        html
      end

      def render_item(item)
        html = "    <li>\n"

        html += if item[:path]
                  "      <a href=\"#{item[:path]}\">#{item[:title]}</a>\n"
                else
                  "      <span>#{item[:title]}</span>\n"
                end

        html += render_tree(item[:children]) unless item[:children].empty?

        html += "    </li>\n"
        html
      end
    end
  end
end
