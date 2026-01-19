# frozen_string_literal: true

require_relative "config_builder"
require_relative "auto_builder"
require_relative "distributed_builder"
require_relative "local_config_loader"

module Docyard
  module Sidebar
    class Cache
      attr_reader :docs_path, :config, :tree, :built_at

      def initialize(docs_path:, config:)
        @docs_path = docs_path
        @config = config
        @tree = nil
        @built_at = nil
      end

      def build
        @tree = build_tree
        @built_at = Time.now
        @tree
      end

      def get(current_path: "/")
        return nil unless @tree

        mark_active_items(@tree, current_path)
      end

      def invalidate
        @tree = nil
        @built_at = nil
      end

      def valid?
        !@tree.nil?
      end

      private

      def build_tree
        case config.sidebar
        when "auto"
          AutoBuilder.new(docs_path, current_path: "/").build
        when "distributed"
          DistributedBuilder.new(docs_path, current_path: "/").build
        else
          build_config_tree
        end
      end

      def build_config_tree
        config_items = LocalConfigLoader.new(docs_path).load
        return [] unless config_items

        ConfigBuilder.new(config_items, current_path: "/").build
      end

      def mark_active_items(items, current_path)
        deep_copy_with_active(items, current_path)
      end

      def deep_copy_with_active(items, current_path)
        items.map do |item|
          copied = item.dup
          copied[:active] = path_matches?(copied[:path], current_path)
          copied[:children] = deep_copy_with_active(item[:children] || [], current_path)
          copied[:collapsed] = determine_collapsed_for_copy(copied)
          copied
        end
      end

      def path_matches?(item_path, current_path)
        return false if item_path.nil?

        normalized_item = Utils::PathResolver.normalize(item_path)
        normalized_current = Utils::PathResolver.normalize(current_path)
        normalized_item == normalized_current
      end

      def determine_collapsed_for_copy(item)
        return false if item[:section]
        return false if item[:active]
        return false if child_active?(item[:children] || [])

        item[:collapsed]
      end

      def child_active?(children)
        children.any? { |child| child[:active] || child_active?(child[:children] || []) }
      end
    end
  end
end
