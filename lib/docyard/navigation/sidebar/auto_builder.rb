# frozen_string_literal: true

require_relative "item"

module Docyard
  module Sidebar
    class AutoBuilder
      attr_reader :docs_path, :current_path

      def initialize(docs_path, current_path: "/")
        @docs_path = docs_path
        @current_path = Utils::PathResolver.normalize(current_path)
      end

      def build
        return [] unless File.directory?(docs_path)

        scan_directory("").map(&:to_h)
      end

      private

      def scan_directory(relative_path, depth: 1)
        full_path = File.join(docs_path, relative_path)
        return [] unless File.directory?(full_path)

        entries = sorted_entries(full_path, relative_path)
        entries.map { |entry| build_item(entry, relative_path, depth) }.compact
      end

      def sorted_entries(full_path, relative_path)
        Dir.children(full_path)
          .reject { |entry| ignored_entry?(entry, relative_path) }
          .sort_by(&:downcase)
      end

      def build_item(entry, relative_path, depth)
        entry_relative_path = build_relative_path(relative_path, entry)
        entry_full_path = File.join(docs_path, entry_relative_path)

        if File.directory?(entry_full_path)
          build_directory_item(entry, entry_relative_path, depth)
        elsif entry.end_with?(".md")
          build_file_item(entry, entry_relative_path)
        end
      end

      def build_relative_path(relative_path, entry)
        relative_path.empty? ? entry : File.join(relative_path, entry)
      end

      def build_directory_item(name, relative_path, depth)
        children = scan_directory(relative_path, depth: depth + 1)
        return nil if children.empty?

        url_path = "/#{relative_path}"
        has_index = File.file?(File.join(docs_path, relative_path, "index.md"))

        Item.new(
          slug: name,
          text: Utils::TextFormatter.titleize(name),
          path: has_index ? url_path : nil,
          type: :directory,
          section: depth == 1,
          collapsed: depth > 1 && !child_active?(children),
          has_index: has_index,
          active: has_index && current_path == url_path,
          items: children
        )
      end

      def build_file_item(filename, relative_path)
        slug = filename.delete_suffix(".md")
        url_path = "/#{relative_path.delete_suffix('.md')}"

        Item.new(
          slug: slug,
          text: Utils::TextFormatter.titleize(slug),
          path: url_path,
          type: :file,
          section: false,
          active: current_path == url_path,
          items: []
        )
      end

      def ignored_entry?(entry, relative_path)
        entry.start_with?(".") ||
          entry.start_with?("_") ||
          root_index?(entry, relative_path) ||
          public_folder?(entry, relative_path)
      end

      def root_index?(entry, relative_path)
        entry == "index.md" && relative_path.empty?
      end

      def public_folder?(entry, relative_path)
        entry == "public" && relative_path.empty?
      end

      def child_active?(children)
        children.any? { |child| child.active || child_active?(child.items) }
      end
    end
  end
end
