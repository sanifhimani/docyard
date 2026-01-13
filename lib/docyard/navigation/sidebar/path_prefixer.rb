# frozen_string_literal: true

module Docyard
  module Sidebar
    class PathPrefixer
      def initialize(tree, prefix)
        @tree = tree
        @prefix = prefix
      end

      def prefix
        return @tree if @prefix.empty?

        @tree.map { |item| prefix_item(item) }
      end

      private

      def prefix_item(item)
        prefixed = item.dup
        prefixed[:path] = prefixed_path(prefixed[:path])
        prefixed[:children] = self.class.new(prefixed[:children], @prefix).prefix if prefixed[:children]&.any?
        prefixed
      end

      def prefixed_path(path)
        return path if path.nil? || path.start_with?("http")

        path_without_slash = path.sub(%r{^/}, "")
        path_without_slash.empty? ? @prefix : "#{@prefix}/#{path_without_slash}"
      end
    end
  end
end
