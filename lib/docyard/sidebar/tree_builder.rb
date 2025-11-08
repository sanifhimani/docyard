# frozen_string_literal: true

module Docyard
  module Sidebar
    class TreeBuilder
      attr_reader :docs_path, :current_path, :title_extractor

      def initialize(docs_path:, current_path:, title_extractor: TitleExtractor.new)
        @docs_path = docs_path
        @current_path = normalize_path(current_path)
        @title_extractor = title_extractor
      end

      def build(file_items)
        transform_items(file_items, "")
      end

      private

      def transform_items(items, relative_base)
        items.map do |item|
          if item[:type] == :directory
            transform_directory(item, relative_base)
          else
            transform_file(item, relative_base)
          end
        end
      end

      def transform_directory(item, relative_base)
        dir_path = File.join(relative_base, item[:name])

        {
          title: titleize(item[:name]),
          path: nil,
          active: false,
          type: :directory,
          collapsible: true,
          collapsed: false,
          children: transform_items(item[:children], dir_path)
        }
      end

      def transform_file(item, relative_base)
        file_path = File.join(relative_base, "#{item[:name]}.md")
        full_file_path = File.join(docs_path, file_path)
        url_path = url_for(file_path.delete_suffix(".md"))

        {
          title: title_extractor.extract(full_file_path),
          path: url_path,
          active: current_path == url_path,
          type: :file,
          children: []
        }
      end

      def titleize(string)
        string.gsub(/[-_]/, " ")
              .split
              .map(&:capitalize)
              .join(" ")
      end

      def url_for(relative_path)
        path = relative_path
               .delete_suffix(".md")
               .delete_suffix("/index")

        path = "/" if path.empty?
        path = "/#{path}" unless path.start_with?("/")

        path
      end

      def normalize_path(path)
        return "/" if path.nil? || path.empty?

        path = path.delete_suffix(".md")
        path = "/" if path.empty?
        path = "/#{path}" unless path.start_with?("/")

        path
      end

      def path_is_ancestor_of_current?(dir_path)
        return false if dir_path.nil?

        current_path.start_with?(dir_path) && current_path != dir_path
      end
    end
  end
end
