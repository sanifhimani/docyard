# frozen_string_literal: true

module Docyard
  module Sidebar
    class ChildrenDiscoverer
      attr_reader :docs_path

      def initialize(docs_path:)
        @docs_path = docs_path
      end

      def discover(relative_path, depth:, &item_builder)
        full_path = File.join(docs_path, relative_path)
        return [] unless File.directory?(full_path)

        local_config = load_local_sidebar_config(full_path)
        return yield(local_config, relative_path, depth) if local_config

        discover_from_filesystem(full_path, relative_path, depth, &item_builder)
      end

      private

      def load_local_sidebar_config(dir_path)
        LocalConfigLoader.new(dir_path).load
      end

      def discover_from_filesystem(full_path, relative_path, depth, &item_builder)
        entries = filtered_entries(full_path)
        entries.map { |entry| build_entry(entry, full_path, relative_path, depth, &item_builder) }.compact
      end

      def filtered_entries(full_path)
        Dir.children(full_path)
          .reject { |e| e.start_with?(".") || e.start_with?("_") || e == "index.md" }
          .sort
      end

      def build_entry(entry, full_path, relative_path, depth)
        entry_path = File.join(full_path, entry)

        if File.directory?(entry_path)
          yield(:directory, entry, relative_path, depth)
        elsif entry.end_with?(".md")
          slug = entry.delete_suffix(".md")
          yield(:file, slug, relative_path, depth)
        end
      end
    end
  end
end
