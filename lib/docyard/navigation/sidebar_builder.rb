# frozen_string_literal: true

require_relative "sidebar/file_system_scanner"
require_relative "sidebar/title_extractor"
require_relative "sidebar/tree_builder"
require_relative "sidebar/renderer"
require_relative "sidebar/config_parser"
require_relative "sidebar/local_config_loader"

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
      if local_config_items?
        build_tree_from_config(local_config_items)
      else
        build_tree_from_filesystem
      end
    end

    def build_tree_from_config(items)
      config_parser(items).parse.map(&:to_h)
    end

    def build_tree_from_filesystem
      file_items = scanner.scan
      tree_builder.build(file_items)
    end

    def local_config_items?
      local_config_items&.any?
    end

    def local_config_items
      @local_config_items ||= local_config_loader.load
    end

    def local_config_loader
      @local_config_loader ||= Sidebar::LocalConfigLoader.new(docs_path)
    end

    def config_parser(items)
      Sidebar::ConfigParser.new(
        items,
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
      config&.build&.base || "/"
    end

    def extract_site_title
      config&.title || "Documentation"
    end
  end
end
