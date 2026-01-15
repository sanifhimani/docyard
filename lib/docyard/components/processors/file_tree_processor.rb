# frozen_string_literal: true

require_relative "../base_processor"
require_relative "../../rendering/icons"

module Docyard
  module Components
    module Processors
      class FileTreeProcessor < BaseProcessor
        FILETREE_PATTERN = /```filetree\n(.*?)```/m

        self.priority = 8

        def preprocess(content)
          content.gsub(FILETREE_PATTERN) do
            tree_content = Regexp.last_match(1)
            build_file_tree(tree_content)
          end
        end

        private

        def build_file_tree(content)
          lines = content.lines.map(&:chomp).reject(&:empty?)

          items = parse_tree_structure(lines)
          html = render_tree(items)

          "\n\n<div class=\"docyard-filetree\" markdown=\"0\">\n#{html}</div>\n\n"
        end

        def parse_tree_structure(lines)
          root_items = []
          stack = [{ indent: -1, children: root_items }]

          lines.each { |line| process_line(line, stack) }

          root_items
        end

        def process_line(line, stack)
          indent = line[/\A */].length
          name = line.strip
          return if name.empty?

          item = build_item(name, indent)
          unwind_stack(stack, indent)
          stack.last[:children] << item

          add_folder_to_stack(item, indent, stack) if item[:type] == :folder
        end

        def build_item(name, indent)
          item = parse_item(name)
          item[:indent] = indent
          item
        end

        def unwind_stack(stack, indent)
          stack.pop while stack.length > 1 && stack.last[:indent] >= indent
        end

        def add_folder_to_stack(item, indent, stack)
          item[:children] = []
          stack.push({ indent: indent, children: item[:children] })
        end

        def parse_item(name)
          highlighted = name.end_with?(" *")
          name = name.chomp(" *") if highlighted

          name, comment = extract_comment(name)
          type = name.end_with?("/") ? :folder : :file
          name = name.chomp("/") if type == :folder

          { name: name, type: type, highlighted: highlighted, comment: comment }
        end

        def extract_comment(name)
          return [name, nil] unless name.include?(" # ")

          name.split(" # ", 2)
        end

        def render_tree(items, depth = 0)
          return "" if items.empty?

          html = "<ul class=\"docyard-filetree__list\">\n"
          items.each { |item| html += render_item(item, depth) }
          html += "</ul>\n"
          html
        end

        def render_item(item, depth)
          classes = item_classes(item)

          html = "<li class=\"#{classes}\">\n"
          html += render_entry(item)
          html += render_tree(item[:children], depth + 1) if render_children?(item)
          html += "</li>\n"
          html
        end

        def item_classes(item)
          classes = ["docyard-filetree__item", "docyard-filetree__item--#{item[:type]}"]
          classes << "docyard-filetree__item--highlighted" if item[:highlighted]
          classes.join(" ")
        end

        def render_entry(item)
          html = "<span class=\"docyard-filetree__entry\">"
          html += icon_for(item[:type])
          html += "<span class=\"docyard-filetree__name\">#{escape_html(item[:name])}</span>"
          html += render_comment(item[:comment])
          html += "</span>"
          html
        end

        def render_comment(comment)
          return "" unless comment

          "<span class=\"docyard-filetree__comment\">#{escape_html(comment)}</span>"
        end

        def render_children?(item)
          item[:type] == :folder && item[:children] && !item[:children].empty?
        end

        def icon_for(type)
          icon_name = type == :folder ? "folder-open" : "file-text"
          Icons.render(icon_name)
        end

        def escape_html(text)
          text.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub('"', "&quot;")
        end
      end
    end
  end
end
