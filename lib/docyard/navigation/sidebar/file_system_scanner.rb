# frozen_string_literal: true

module Docyard
  module Sidebar
    class FileSystemScanner
      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
      end

      def scan
        return [] unless File.directory?(docs_path)

        scan_directory(docs_path, "")
      end

      private

      def scan_directory(base_path, relative_path)
        full_path = File.join(base_path, relative_path)
        return [] unless File.directory?(full_path)

        entries = sorted_entries(full_path, relative_path)
        entries.map { |entry| build_item(entry, base_path, relative_path, full_path) }.compact
      end

      def sorted_entries(full_path, relative_path)
        Dir.children(full_path)
          .reject { |entry| hidden_or_ignored?(entry, relative_path) }
          .sort_by { |entry| sort_key(entry) }
      end

      def build_item(entry, base_path, relative_path, full_path)
        entry_full_path = File.join(full_path, entry)
        entry_relative_path = build_relative_path(relative_path, entry)

        if File.directory?(entry_full_path)
          build_directory_item(entry, entry_relative_path, base_path)
        elsif entry.end_with?(".md")
          build_file_item(entry, entry_relative_path)
        end
      end

      def build_relative_path(relative_path, entry)
        relative_path.empty? ? entry : File.join(relative_path, entry)
      end

      def build_directory_item(entry, entry_relative_path, base_path)
        {
          type: :directory,
          name: entry,
          path: entry_relative_path,
          children: scan_directory(base_path, entry_relative_path)
        }
      end

      def build_file_item(entry, entry_relative_path)
        {
          type: :file,
          name: entry.delete_suffix(".md"),
          path: entry_relative_path
        }
      end

      def hidden_or_ignored?(entry, relative_path)
        entry.start_with?(".") ||
          entry.start_with?("_") ||
          (entry == "index.md" && relative_path.empty?) ||
          (entry == "public" && relative_path.empty?)
      end

      def sort_key(entry)
        entry.downcase
      end
    end
  end
end
