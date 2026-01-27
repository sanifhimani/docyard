# frozen_string_literal: true

module Docyard
  class Doctor
    class OrphanChecker
      attr_reader :docs_path, :config

      def initialize(docs_path, config)
        @docs_path = docs_path
        @config = config
      end

      def check
        return [] if auto_sidebar?

        sidebar_pages = collect_sidebar_pages
        return [] unless sidebar_pages

        all_pages = collect_all_pages
        orphans = all_pages - sidebar_pages

        orphans.map { |file| { file: file } }
      end

      private

      def auto_sidebar?
        config.sidebar == "auto"
      end

      def collect_all_pages
        Dir.glob(File.join(docs_path, "**", "*.md"))
          .map { |f| f.delete_prefix("#{docs_path}/") }
          .reject { |f| f.start_with?("_") || f == "index.md" }
      end

      def collect_sidebar_pages
        config_items = load_sidebar_config
        return nil unless config_items

        sidebar_tree = Sidebar::ConfigBuilder.new(config_items, current_path: "/").build
        extract_paths_from_tree(sidebar_tree)
      end

      def load_sidebar_config
        Sidebar::LocalConfigLoader.new(docs_path).load
      end

      def extract_paths_from_tree(items, collected = [])
        items.each do |item|
          path = item[:path]
          collected << path_to_file(path) if path && !item[:link]
          extract_paths_from_tree(item[:children] || [], collected)
        end
        collected
      end

      def path_to_file(url_path)
        clean_path = url_path.delete_prefix("/").chomp("/")
        return "index.md" if clean_path.empty?

        if File.exist?(File.join(docs_path, clean_path, "index.md"))
          "#{clean_path}/index.md"
        else
          "#{clean_path}.md"
        end
      end
    end
  end
end
