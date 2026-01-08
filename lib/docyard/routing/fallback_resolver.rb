# frozen_string_literal: true

module Docyard
  module Routing
    class FallbackResolver
      attr_reader :docs_path, :sidebar_builder

      def initialize(docs_path:, sidebar_builder:)
        @docs_path = docs_path
        @sidebar_builder = sidebar_builder
      end

      def resolve_fallback(request_path)
        return nil if file_exists?(request_path)

        find_first_item_in_section(request_path)
      end

      private

      def file_exists?(request_path)
        clean_path = sanitize_path(request_path)

        file_path = File.join(docs_path, "#{clean_path}.md")
        return true if File.file?(file_path)

        index_path = File.join(docs_path, clean_path, "index.md")
        File.file?(index_path)
      end

      def sanitize_path(request_path)
        clean = request_path.to_s.delete_prefix("/").delete_suffix("/")
        clean = "index" if clean.empty?
        clean.delete_suffix(".md")
      end

      def find_first_item_in_section(request_path)
        tree = sidebar_builder.tree

        if root_path?(request_path)
          find_first_navigable_item(tree)
        else
          section = find_section_in_tree(tree, request_path)
          section ? find_first_navigable_item(section[:children] || []) : nil
        end
      end

      def root_path?(request_path)
        request_path.nil? || request_path == "/" || request_path.empty?
      end

      def find_section_in_tree(tree, path)
        normalized_path = normalize_path(path)

        tree.each do |item|
          return item if path_matches_section?(item, normalized_path)

          if item[:children]&.any?
            found = find_section_in_tree(item[:children], path)
            return found if found
          end
        end

        nil
      end

      def normalize_path(path)
        path.to_s.delete_prefix("/").delete_suffix("/").downcase
      end

      def path_matches_section?(item, normalized_path)
        return false unless item[:type] == :directory

        item_path = item[:title].to_s.downcase.gsub(/\s+/, "-")
        item_path == normalized_path
      end

      def find_first_navigable_item(items)
        items.each do |item|
          return item[:path] if item[:path] && item[:type] == :file

          if item[:children]&.any?
            found = find_first_navigable_item(item[:children])
            return found if found
          end
        end

        nil
      end
    end
  end
end
