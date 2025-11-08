# frozen_string_literal: true

require_relative "sidebar/file_system_scanner"
require_relative "sidebar/title_extractor"
require_relative "sidebar/tree_builder"
require_relative "sidebar/renderer"

module Docyard
  class SidebarBuilder
    attr_reader :docs_path, :current_path, :config

    def initialize(docs_path:, current_path: "/", config: {})
      @docs_path = docs_path
      @current_path = current_path
      @config = config
    end

    def tree
      @tree ||= build_tree
    end

    def to_html
      renderer.render(tree)
    end

    private

    def build_tree
      file_items = scanner.scan
      tree_builder.build(file_items)
    end

    def scanner
      @scanner ||= Sidebar::FileSystemScanner.new(docs_path)
    end

    def tree_builder
      @tree_builder ||= Sidebar::TreeBuilder.new(
        docs_path: docs_path,
        current_path: current_path
      )
    end

    def renderer
      @renderer ||= Sidebar::Renderer.new(
        site_title: config[:site_title] || "Documentation"
      )
    end
  end
end
