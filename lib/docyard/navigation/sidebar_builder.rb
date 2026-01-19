# frozen_string_literal: true

require_relative "sidebar/cache"
require_relative "sidebar/config_builder"
require_relative "sidebar/auto_builder"
require_relative "sidebar/distributed_builder"
require_relative "sidebar/renderer"
require_relative "sidebar/tree_filter"
require_relative "sidebar/local_config_loader"

module Docyard
  class SidebarBuilder
    attr_reader :docs_path, :current_path, :config, :header_ctas, :sidebar_cache

    def initialize(docs_path:, current_path: "/", config: nil, header_ctas: [], sidebar_cache: nil)
      @docs_path = docs_path
      @current_path = current_path
      @config = config
      @header_ctas = header_ctas
      @sidebar_cache = sidebar_cache
    end

    def tree
      @tree ||= build_tree
    end

    def to_html
      renderer.render(tree)
    end

    private

    def build_tree
      return build_from_cache if sidebar_cache&.valid?

      build_without_cache
    end

    def build_from_cache
      base_tree = sidebar_cache.get(current_path: current_path)
      apply_tab_scoping(base_tree)
    end

    def build_without_cache
      base_tree = build_tree_for_mode
      apply_tab_scoping(base_tree)
    end

    def build_tree_for_mode
      case sidebar_mode
      when "auto"
        Sidebar::AutoBuilder.new(docs_path, current_path: current_path).build
      when "distributed"
        Sidebar::DistributedBuilder.new(docs_path, current_path: current_path).build
      else
        build_config_tree
      end
    end

    def build_config_tree
      config_items = Sidebar::LocalConfigLoader.new(docs_path).load
      return [] unless config_items

      Sidebar::ConfigBuilder.new(config_items, current_path: current_path).build
    end

    def sidebar_mode
      config&.sidebar || "config"
    end

    def apply_tab_scoping(base_tree)
      return base_tree if sidebar_mode == "auto"
      return base_tree unless tabs_configured?

      active_tab = find_active_tab
      return base_tree unless active_tab

      filter_tree_for_tab(base_tree, active_tab)
    end

    def filter_tree_for_tab(base_tree, tab)
      tab_path = tab["href"]&.chomp("/")
      return base_tree if empty_tab_path?(tab_path)

      Sidebar::TreeFilter.new(base_tree, tab_path).filter
    end

    def empty_tab_path?(tab_path)
      tab_path.nil? || tab_path.empty? || tab_path == "/"
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
