# frozen_string_literal: true

require_relative "sidebar/file_system_scanner"
require_relative "sidebar/title_extractor"
require_relative "sidebar/tree_builder"
require_relative "sidebar/renderer"
require_relative "sidebar/config_parser"
require_relative "sidebar/local_config_loader"
require_relative "sidebar/path_prefixer"
require_relative "sidebar/tree_filter"

module Docyard
  class SidebarBuilder
    attr_reader :docs_path, :current_path, :config, :header_ctas

    def initialize(docs_path:, current_path: "/", config: nil, header_ctas: [])
      @docs_path = docs_path
      @current_path = current_path
      @config = config
      @header_ctas = header_ctas
    end

    def tree
      @tree ||= build_scoped_tree
    end

    def to_html
      renderer.render(tree)
    end

    private

    def build_scoped_tree
      active_tab = find_active_tab
      return build_tree_for_path(docs_path) unless active_tab

      build_tree_for_tab(active_tab)
    end

    def build_tree_for_tab(tab)
      tab_path = tab["href"]&.chomp("/")
      return build_tree_for_path(docs_path) if empty_tab_path?(tab_path)

      scoped_docs_path = resolve_scoped_path(tab_path)
      build_scoped_or_filtered_tree(scoped_docs_path, tab_path)
    end

    def empty_tab_path?(tab_path)
      tab_path.nil? || tab_path.empty? || tab_path == "/"
    end

    def resolve_scoped_path(tab_path)
      tab_folder = tab_path.sub(%r{^/}, "")
      File.join(docs_path, tab_folder)
    end

    def build_scoped_or_filtered_tree(scoped_docs_path, tab_path)
      if scoped_sidebar_available?(scoped_docs_path)
        build_tree_for_path(scoped_docs_path, base_url_prefix: tab_path)
      else
        Sidebar::TreeFilter.new(build_tree_for_path(docs_path), tab_path).filter
      end
    end

    def scoped_sidebar_available?(path)
      File.directory?(path) && Sidebar::LocalConfigLoader.new(path).config_file_exists?
    end

    def build_tree_for_path(path, base_url_prefix: "")
      config_items = Sidebar::LocalConfigLoader.new(path).load
      tree = build_tree(config_items, path, base_url_prefix)
      maybe_prepend_overview(tree, path, base_url_prefix)
    end

    def build_tree(config_items, path, base_url_prefix)
      if config_items&.any?
        build_tree_from_config(config_items, path, base_url_prefix)
      else
        build_tree_from_filesystem(path, base_url_prefix)
      end
    end

    def maybe_prepend_overview(tree, path, base_url_prefix)
      return tree if skip_overview?(tree, path, base_url_prefix)

      [build_overview_item(base_url_prefix)] + tree
    end

    def skip_overview?(tree, path, base_url_prefix)
      base_url_prefix.empty? ||
        tree.first&.dig(:section) ||
        !File.file?(File.join(path, "index.md")) ||
        tree.any? { |item| item[:path] == base_url_prefix }
    end

    def build_overview_item(base_url_prefix)
      {
        title: "Overview", path: base_url_prefix, icon: nil,
        active: current_path == base_url_prefix, type: :file,
        collapsed: false, collapsible: false, target: "_self",
        has_index: false, section: false, children: []
      }
    end

    def build_tree_from_config(items, path, base_url_prefix)
      tree = Sidebar::ConfigParser.new(
        items, docs_path: path, current_path: current_path_relative_to(base_url_prefix)
      ).parse.map(&:to_h)

      Sidebar::PathPrefixer.new(tree, base_url_prefix).prefix
    end

    def build_tree_from_filesystem(path, base_url_prefix)
      file_items = Sidebar::FileSystemScanner.new(path).scan
      tree = Sidebar::TreeBuilder.new(
        docs_path: path, current_path: current_path_relative_to(base_url_prefix)
      ).build(file_items)

      Sidebar::PathPrefixer.new(tree, base_url_prefix).prefix
    end

    def current_path_relative_to(prefix)
      return current_path if prefix.empty?
      return current_path unless current_path.start_with?(prefix)

      relative = current_path.sub(prefix, "")
      relative.empty? ? "/" : relative
    end

    def renderer
      @renderer ||= Sidebar::Renderer.new(
        site_title: config&.title || "Documentation",
        base_url: config&.build&.base || "/",
        header_ctas: header_ctas
      )
    end

    def tabs_configured?
      tabs = config&.tabs
      tabs.is_a?(Array) && tabs.any?
    end

    def find_active_tab
      return nil unless tabs_configured?

      normalized_current = current_path.chomp("/")
      config.tabs.find { |tab| tab_matches_current?(tab, normalized_current) }
    end

    def tab_matches_current?(tab, normalized_current)
      return false if tab["external"]

      tab_href = tab["href"]&.chomp("/")
      return false if tab_href.nil?

      normalized_current == tab_href || normalized_current.start_with?("#{tab_href}/")
    end
  end
end
