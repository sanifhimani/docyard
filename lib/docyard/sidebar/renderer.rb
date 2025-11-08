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

        html = "<aside class=\"sidebar\" role=\"navigation\" aria-label=\"Documentation navigation\">\n"
        html += "  <nav>\n"
        html += render_tree_with_sections(tree)
        html += "  </nav>\n"
        html += render_footer
        html += "</aside>\n"
        html
      end

      private

      def render_footer
        <<~HTML
          <div class="sidebar-footer">
            #{footer_link}
          </div>
        HTML
      end

      def footer_link
        <<~HTML
          <a href="https://github.com/sanifhimani/docyard"
             target="_blank"
             rel="noopener noreferrer"
             class="sidebar-footer-link">
            <div class="sidebar-footer-text">
              <p class="sidebar-footer-title">Built with docyard</p>
            </div>
            #{external_icon}
          </a>
        HTML
      end

      def external_icon
        '<svg class="external-icon" xmlns="http://www.w3.org/2000/svg" ' \
          'viewBox="0 0 256 256" fill="currentColor">' \
          '<path d="M224,104a8,8,0,0,1-16,0V59.32l-66.33,66.34a8,8,0,0,1-11.32-11.32' \
          "L196.68,48H152a8,8,0,0,1,0-16h64a8,8,0,0,1,8,8Zm-40,24a8,8,0,0,0-8,8v72H48V80h72" \
          "a8,8,0,0,0,0-16H48A16,16,0,0,0,32,80V208a16,16,0,0,0,16,16H176a16,16,0,0,0,16-16" \
          'V136A8,8,0,0,0,184,128Z"/>' \
          "</svg>"
      end

      def render_tree_with_sections(items)
        filtered_items = items.reject { |item| item[:title]&.downcase == site_title.downcase }
        grouped_items = group_by_section(filtered_items)
        html = ""

        grouped_items.each do |section_name, section_items|
          html += "  <div class=\"nav-section\">\n"
          html += "    <div class=\"nav-section-title\">#{section_name}</div>\n" if section_name
          html += render_tree(section_items)
          html += "  </div>\n"
        end

        html
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

        html = "  <ul>\n"
        items.each { |item| html += render_item(item) }
        html += "  </ul>\n"
        html
      end

      def render_item(item)
        html = "    <li>\n"

        html += if item[:children].empty?
                  render_leaf_item(item)
                else
                  render_group_item(item)
                end

        html += "    </li>\n"
        html
      end

      def render_leaf_item(item)
        active_class = item[:active] ? " class=\"active\"" : ""
        "      <a href=\"#{item[:path]}\"#{active_class}>#{item[:title]}</a>\n"
      end

      def render_group_item(item)
        html = "      <button class=\"nav-group-toggle\" aria-expanded=\"true\" type=\"button\">\n"
        html += "        <span>#{item[:title]}</span>\n"
        html += nav_group_icon
        html += "      </button>\n"
        html += "      <div class=\"nav-group-children\">\n"
        html += render_tree(item[:children])
        html += "      </div>\n"
        html
      end

      def nav_group_icon
        '<svg class="nav-group-icon" xmlns="http://www.w3.org/2000/svg" ' \
          'viewBox="0 0 256 256" fill="currentColor">' \
          '<path d="M181.66,133.66l-80,80a8,8,0,0,1-11.32-11.32L164.69,128,' \
          '90.34,53.66a8,8,0,0,1,11.32-11.32l80,80A8,8,0,0,1,181.66,133.66Z"/>' \
          "</svg>\n"
      end
    end
  end
end
