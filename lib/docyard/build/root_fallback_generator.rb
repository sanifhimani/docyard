# frozen_string_literal: true

module Docyard
  module Build
    class RootFallbackGenerator
      attr_reader :config, :docs_path, :sidebar_cache, :renderer

      def initialize(config:, docs_path:, sidebar_cache:, renderer:)
        @config = config
        @docs_path = docs_path
        @sidebar_cache = sidebar_cache
        @renderer = renderer
      end

      def generate_if_needed
        return if root_index_exists?

        first_path = find_first_navigable_path
        return unless first_path

        generate_redirect_page(first_path)
      end

      private

      def root_index_exists?
        File.exist?(File.join(docs_path, "index.md")) ||
          File.exist?(File.join(docs_path, "index.html"))
      end

      def find_first_navigable_path
        return nil unless sidebar_cache&.tree&.any?

        find_first_file_in_tree(sidebar_cache.tree)
      end

      def find_first_file_in_tree(items)
        items.each do |item|
          return item[:path] if item[:type] == :file && item[:path]

          if item[:children]&.any?
            nested = find_first_file_in_tree(item[:children])
            return nested if nested
          end
        end

        nil
      end

      def generate_redirect_page(target_path)
        output_path = File.join(config.build.output, "index.html")
        full_target = build_full_target_url(target_path)

        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, renderer.render_redirect(full_target))

        full_target
      end

      def build_full_target_url(target_path)
        base = config.build.base&.chomp("/") || ""
        "#{base}#{target_path}"
      end
    end
  end
end
