# frozen_string_literal: true

require_relative "renderer"
require_relative "utils/path_resolver"

module Docyard
  class PrevNextBuilder
    attr_reader :sidebar_tree, :current_path, :frontmatter, :config

    def initialize(sidebar_tree:, current_path:, frontmatter: {}, config: {})
      @sidebar_tree = sidebar_tree
      @current_path = Utils::PathResolver.normalize(current_path)
      @frontmatter = frontmatter
      @config = config
    end

    def prev_next_links
      return nil unless enabled?

      {
        prev: build_prev_link,
        next: build_next_link
      }
    end

    def to_html
      links = prev_next_links
      return "" if links.nil? || (links[:prev].nil? && links[:next].nil?)

      Renderer.new.render_partial(
        "_prev_next", {
          prev: links[:prev],
          next: links[:next],
          prev_text: config_prev_text,
          next_text: config_next_text
        }
      )
    end

    private

    def enabled?
      return false if config_disabled?
      return false if frontmatter_disabled?

      true
    end

    def config_disabled?
      return false if config.nil? || config.empty?

      config == false || config["enabled"] == false || config[:enabled] == false
    end

    def frontmatter_disabled?
      frontmatter["prev"] == false && frontmatter["next"] == false
    end

    def build_prev_link
      return nil if frontmatter["prev"] == false

      return build_frontmatter_link(frontmatter["prev"]) if frontmatter["prev"]

      auto_prev_link
    end

    def build_next_link
      return nil if frontmatter["next"] == false

      return build_frontmatter_link(frontmatter["next"]) if frontmatter["next"]

      auto_next_link
    end

    def build_frontmatter_link(value)
      case value
      when String
        find_link_by_text(value)
      when Hash
        {
          title: value["text"] || value[:text],
          path: value["link"] || value[:link]
        }
      end
    end

    def find_link_by_text(text)
      flat_links.find { |link| link[:title].downcase == text.downcase }
    end

    def auto_prev_link
      index = current_page_index
      return nil unless index&.positive?

      flat_links[index - 1]
    end

    def auto_next_link
      index = current_page_index
      return nil unless index && index < flat_links.length - 1

      flat_links[index + 1]
    end

    def current_page_index
      @current_page_index ||= flat_links.find_index do |link|
        normalized_path(link[:path]) == normalized_path(current_path)
      end
    end

    def flat_links
      @flat_links ||= begin
        links = []
        flatten_tree(sidebar_tree, links)
        links.uniq { |link| normalized_path(link[:path]) }
      end
    end

    def flatten_tree(items, links)
      items.each do |item|
        links << build_link(item) if valid_navigation_item?(item)
        flatten_tree(item[:children], links) if item[:children]&.any?
      end
    end

    def valid_navigation_item?(item)
      item[:type] == :file && item[:path] && !external_link?(item[:path])
    end

    def build_link(item)
      {
        title: item[:footer_text] || item[:title],
        path: item[:path]
      }
    end

    def external_link?(path)
      path.start_with?("http://", "https://")
    end

    def normalized_path(path)
      return "" if path.nil?

      path.gsub(/[?#].*$/, "")
    end

    def config_prev_text
      return "Previous" if config.nil? || config.empty?

      config["prev_text"] || config[:prev_text] || "Previous"
    end

    def config_next_text
      return "Next" if config.nil? || config.empty?

      config["next_text"] || config[:next_text] || "Next"
    end
  end
end
