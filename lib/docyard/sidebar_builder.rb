# frozen_string_literal: true

require_relative "sidebar/file_system_scanner"
require_relative "sidebar/title_extractor"
require_relative "sidebar/tree_builder"
require_relative "sidebar/renderer"
require_relative "sidebar/config_parser"

module Docyard
  class SidebarBuilder
    attr_reader :docs_path, :current_path, :config

    def initialize(docs_path:, current_path: "/", config: nil)
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
      if config_sidebar_items?
        build_tree_from_config
      else
        build_tree_from_filesystem
      end
    end

    def build_tree_from_config
      config_parser.parse.map(&:to_h)
    end

    def build_tree_from_filesystem
      file_items = scanner.scan
      tree_builder.build(file_items)
    end

    def config_sidebar_items?
      config_sidebar_items&.any?
    end

    def config_sidebar_items
      return [] unless config

      if config.is_a?(Hash)
        config.dig("sidebar", "items") || config.dig(:sidebar, :items) || []
      else
        config.sidebar&.items || []
      end
    end

    def config_parser
      @config_parser ||= Sidebar::ConfigParser.new(
        config_sidebar_items,
        docs_path: docs_path,
        current_path: current_path
      )
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
        site_title: extract_site_title,
        base_url: extract_base_url
      )
    end

    def extract_base_url
      if config.is_a?(Hash)
        config.dig(:build, :base_url) || "/"
      else
        config&.build&.base_url || "/"
      end
    end

    def extract_site_title
      if config.is_a?(Hash)
        config[:site_title] || "Documentation"
      else
        config&.site&.title || "Documentation"
      end
    end
  end
end
