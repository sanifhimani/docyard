# frozen_string_literal: true

require_relative "sidebar_builder"
require_relative "prev_next_builder"
require_relative "breadcrumb_builder"

module Docyard
  module Navigation
    class PageNavigationBuilder
      def initialize(docs_path:, config:, sidebar_cache: nil, base_url: "/")
        @docs_path = docs_path
        @config = config
        @sidebar_cache = sidebar_cache
        @base_url = base_url
      end

      def build(current_path:, markdown:, header_ctas: [], show_sidebar: true)
        return empty_navigation unless show_sidebar

        sidebar_builder = build_sidebar(current_path, header_ctas)
        {
          sidebar_html: sidebar_builder.to_html,
          prev_next_html: build_prev_next(sidebar_builder, current_path, markdown),
          breadcrumbs: build_breadcrumbs(sidebar_builder.tree, current_path)
        }
      end

      private

      attr_reader :docs_path, :config, :sidebar_cache, :base_url

      def empty_navigation
        { sidebar_html: "", prev_next_html: "", breadcrumbs: nil }
      end

      def build_sidebar(current_path, header_ctas)
        SidebarBuilder.new(
          docs_path: docs_path,
          current_path: current_path,
          config: config,
          header_ctas: header_ctas,
          sidebar_cache: sidebar_cache
        )
      end

      def build_prev_next(sidebar_builder, current_path, markdown)
        PrevNextBuilder.new(
          sidebar_tree: sidebar_builder.tree,
          current_path: current_path,
          frontmatter: markdown.frontmatter,
          config: {},
          base_url: base_url
        ).to_html
      end

      def build_breadcrumbs(sidebar_tree, current_path)
        return nil unless breadcrumbs_enabled?

        BreadcrumbBuilder.new(sidebar_tree: sidebar_tree, current_path: current_path)
      end

      def breadcrumbs_enabled?
        config&.navigation&.breadcrumbs != false
      end
    end
  end
end
