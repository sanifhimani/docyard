# frozen_string_literal: true

module Docyard
  class BreadcrumbBuilder
    MAX_VISIBLE_ITEMS = 3

    Item = Struct.new(:title, :href, :current, keyword_init: true)

    attr_reader :sidebar_tree, :current_path

    def initialize(sidebar_tree:, current_path:)
      @sidebar_tree = sidebar_tree || []
      @current_path = normalize_path(current_path)
    end

    def items
      @items ||= build_items
    end

    def truncated?
      full_path_items.length > MAX_VISIBLE_ITEMS
    end

    def should_show?
      items.any? && !root_page?
    end

    private

    def build_items
      return [] if full_path_items.empty?

      if truncated?
        truncated_items
      else
        full_path_items
      end
    end

    def truncated_items
      path = full_path_items
      [
        Item.new(title: "...", href: nil, current: false),
        path[-2],
        path[-1]
      ].compact
    end

    def full_path_items
      @full_path_items ||= find_breadcrumb_path(sidebar_tree, [])
    end

    def find_breadcrumb_path(nodes, path)
      nodes.each do |node|
        result = process_node(node, path)
        return result if result
      end

      []
    end

    def process_node(node, path)
      node_path = normalize_path(node[:path])
      node_title = truncate_title(node[:title] || "")

      return build_current_item(path, node_title, node_path) if exact_match?(node_path)

      search_in_ancestors(node, path, node_title, node_path) ||
        search_in_children(node, path)
    end

    def build_current_item(path, title, href)
      path + [Item.new(title: title, href: href, current: true)]
    end

    def search_in_ancestors(node, path, title, href)
      return unless node[:children]&.any?

      effective_href = href == "/" ? derive_section_path(node) : href
      return unless path_is_ancestor?(effective_href)

      result = find_breadcrumb_path(
        node[:children],
        path + [Item.new(title: title, href: effective_href, current: false)]
      )
      result.any? ? result : nil
    end

    def derive_section_path(node)
      first_child = node[:children]&.first
      return nil unless first_child

      child_path = first_child[:path]
      return nil if child_path.nil? || child_path.empty?

      File.dirname(child_path)
    end

    def search_in_children(node, path)
      return unless node[:children]&.any?

      result = find_breadcrumb_path(node[:children], path)
      result.any? ? result : nil
    end

    def exact_match?(node_path)
      normalize_path(node_path) == current_path
    end

    def path_is_ancestor?(node_path)
      return false if node_path.nil? || node_path.empty? || node_path == "/"

      normalized = normalize_path(node_path)
      current_path.start_with?("#{normalized}/") || current_path == normalized
    end

    def normalize_path(path)
      return "/" if path.nil? || path.empty?

      path.chomp("/")
    end

    def truncate_title(title)
      return title if title.length <= 30

      "#{title[0, 27]}..."
    end

    def root_page?
      current_path == "/" || current_path.empty?
    end
  end
end
