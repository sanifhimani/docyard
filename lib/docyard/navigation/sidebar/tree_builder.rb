# frozen_string_literal: true

require_relative "sorter"
require_relative "local_config_loader"
require_relative "config_parser"
require_relative "metadata_reader"

module Docyard
  module Sidebar
    class TreeBuilder
      attr_reader :docs_path, :current_path, :title_extractor, :metadata_reader

      def initialize(docs_path:, current_path:, title_extractor: TitleExtractor.new)
        @docs_path = docs_path
        @current_path = Utils::PathResolver.normalize(current_path)
        @title_extractor = title_extractor
        @metadata_reader = MetadataReader.new
      end

      def build(file_items)
        transform_items(file_items, "", depth: 1)
      end

      private

      def transform_items(items, relative_base, depth:)
        transformed = items.map do |item|
          if item[:type] == :directory
            transform_directory(item, relative_base, depth: depth)
          else
            transform_file(item, relative_base)
          end
        end
        Sorter.sort_by_order(transformed)
      end

      def transform_directory(item, relative_base, depth:)
        dir_path = File.join(relative_base, item[:name])
        dir_context = build_directory_context(dir_path)
        children = build_directory_children(item, dir_path, depth)

        if depth == 1
          build_section(item, children, dir_context)
        else
          build_collapsible_group(item, children, dir_context)
        end
      end

      def build_directory_children(item, dir_path, depth)
        full_dir_path = File.join(docs_path, dir_path)
        local_config = LocalConfigLoader.new(full_dir_path).load

        if local_config
          build_children_from_config(local_config, dir_path)
        else
          transform_items(item[:children], dir_path, depth: depth + 1)
        end
      end

      def build_children_from_config(config_items, base_path)
        full_base_path = File.join(docs_path, base_path)
        parser = ConfigParser.new(config_items, docs_path: full_base_path, current_path: current_path)
        parser.parse.map(&:to_h)
      end

      def build_directory_context(dir_path)
        index_file_path = File.join(docs_path, dir_path, "index.md")
        has_index = File.file?(index_file_path)
        { index_file_path: index_file_path, has_index: has_index,
          url_path: has_index ? Utils::PathResolver.to_url(dir_path) : nil }
      end

      def build_section(item, children, context)
        filtered_children = filter_index_from_children(children, context[:url_path])
        metadata = context[:has_index] ? metadata_reader.extract_index_metadata(context[:index_file_path]) : {}

        if context[:has_index]
          overview = build_overview_item(metadata, context[:url_path])
          filtered_children = [overview] + filtered_children
        end

        build_section_hash(item, filtered_children, metadata)
      end

      def build_section_hash(item, children, metadata)
        { title: Utils::TextFormatter.titleize(item[:name]), path: nil, icon: metadata[:icon],
          active: false, type: :directory, section: true,
          collapsed: false, has_index: false, order: metadata[:order], children: children }
      end

      def build_collapsible_group(item, children, context)
        filtered_children = filter_index_from_children(children, context[:url_path])
        metadata = context[:has_index] ? metadata_reader.extract_index_metadata(context[:index_file_path]) : {}
        is_active = context[:has_index] && current_path == context[:url_path]

        build_collapsible_hash(item, filtered_children, context, metadata, is_active)
      end

      def build_collapsible_hash(item, children, context, metadata, is_active)
        { title: Utils::TextFormatter.titleize(item[:name]), path: context[:url_path],
          icon: metadata[:icon], active: is_active, type: :directory, section: false,
          collapsed: collapsible_collapsed?(children, is_active), has_index: context[:has_index],
          order: metadata[:order], children: children }
      end

      def collapsible_collapsed?(children, is_active)
        return false if is_active || active_child?(children)

        true
      end

      def build_overview_item(metadata, url_path)
        { title: metadata[:sidebar_text] || "Overview", path: url_path,
          icon: metadata[:icon], active: current_path == url_path, type: :file, children: [] }
      end

      def filter_index_from_children(children, index_url_path)
        return children unless index_url_path

        children.reject { |child| child[:path] == index_url_path }
      end

      def active_child?(children)
        children.any? { |child| child[:active] || active_child?(child[:children] || []) }
      end

      def transform_file(item, relative_base)
        file_path = File.join(relative_base, "#{item[:name]}#{Constants::MARKDOWN_EXTENSION}")
        full_file_path = File.join(docs_path, file_path)
        url_path = Utils::PathResolver.to_url(file_path.delete_suffix(Constants::MARKDOWN_EXTENSION))
        metadata = metadata_reader.extract_file_metadata(full_file_path)

        { title: metadata[:title] || title_extractor.extract(full_file_path),
          path: url_path, icon: metadata[:icon], active: current_path == url_path,
          type: :file, order: metadata[:order], children: [] }
      end
    end
  end
end
