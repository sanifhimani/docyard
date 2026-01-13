# frozen_string_literal: true

module Docyard
  module Sidebar
    class TreeFilter
      def initialize(tree, tab_path)
        @tree = tree
        @tab_path = tab_path
      end

      def filter
        @tree.filter_map { |item| filter_item(item) }
      end

      private

      def filter_item(item)
        children = item[:children] || []

        if children.any?
          filter_parent_item(item, children)
        else
          filter_leaf_item(item)
        end
      end

      def filter_parent_item(item, children)
        filtered_children = self.class.new(children, @tab_path).filter
        has_matching_content = filtered_children.any? { |c| !external_item?(c) }

        return nil if !has_matching_content && !item_matches_path?(item[:path])

        item.merge(children: filtered_children)
      end

      def filter_leaf_item(item)
        return item if external_item?(item)
        return nil unless item_matches_path?(item[:path])

        item
      end

      def external_item?(item)
        item[:type] == :external || item[:path]&.start_with?("http")
      end

      def item_matches_path?(item_path)
        return false if item_path.nil?

        normalized_path = item_path.chomp("/")
        normalized_path == @tab_path || normalized_path.start_with?("#{@tab_path}/")
      end
    end
  end
end
