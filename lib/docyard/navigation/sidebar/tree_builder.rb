# frozen_string_literal: true

module Docyard
  module Sidebar
    class TreeBuilder
      attr_reader :docs_path, :current_path, :title_extractor

      def initialize(docs_path:, current_path:, title_extractor: TitleExtractor.new)
        @docs_path = docs_path
        @current_path = Utils::PathResolver.normalize(current_path)
        @title_extractor = title_extractor
      end

      def build(file_items)
        transform_items(file_items, "", depth: 1)
      end

      private

      def transform_items(items, relative_base, depth:)
        items.map do |item|
          if item[:type] == :directory
            transform_directory(item, relative_base, depth: depth)
          else
            transform_file(item, relative_base)
          end
        end
      end

      def transform_directory(item, relative_base, depth:)
        dir_path = File.join(relative_base, item[:name])
        children = transform_items(item[:children], dir_path, depth: depth + 1)
        dir_context = build_directory_context(dir_path)

        if depth == 1
          build_section(item, children, dir_context)
        else
          build_group(item, children, dir_context)
        end
      end

      def build_directory_context(dir_path)
        index_file_path = File.join(docs_path, dir_path, "index.md")
        has_index = File.file?(index_file_path)
        {
          index_file_path: index_file_path,
          has_index: has_index,
          url_path: has_index ? Utils::PathResolver.to_url(dir_path) : nil
        }
      end

      def build_section(item, children, context)
        filtered_children = filter_index_from_children(children, context[:url_path])
        metadata = context[:has_index] ? extract_index_metadata(context[:index_file_path]) : {}
        filtered_children = prepend_overview_item(filtered_children, metadata, context) if context[:has_index]

        build_section_hash(item, filtered_children, metadata)
      end

      def prepend_overview_item(children, metadata, context)
        [build_overview_item(metadata, context[:url_path])] + children
      end

      def build_section_hash(item, children, metadata)
        {
          title: Utils::TextFormatter.titleize(item[:name]),
          path: nil,
          icon: metadata[:icon],
          active: false,
          type: :directory,
          collapsible: true,
          collapsed: resolve_collapsed(metadata[:collapsed], children),
          has_index: false,
          children: children
        }
      end

      def build_group(item, children, context)
        metadata = context[:has_index] ? extract_file_metadata(context[:index_file_path]) : {}
        filtered_children = context[:has_index] ? filter_index_from_children(children, context[:url_path]) : children
        is_active = context[:has_index] && current_path == context[:url_path]

        build_group_hash(item, filtered_children, metadata, context, is_active)
      end

      def build_group_hash(item, children, metadata, context, is_active)
        {
          title: metadata[:title] || Utils::TextFormatter.titleize(item[:name]),
          path: context[:url_path],
          icon: metadata[:icon],
          active: is_active,
          type: :directory,
          collapsible: true,
          collapsed: resolve_collapsed(metadata[:collapsed], children, is_active: is_active),
          has_index: context[:has_index],
          children: children
        }
      end

      def resolve_collapsed(explicit_collapsed, children, is_active: false)
        return explicit_collapsed unless explicit_collapsed.nil?

        !is_active && !active_child?(children)
      end

      def build_overview_item(metadata, url_path)
        {
          title: metadata[:sidebar_text] || "Introduction",
          path: url_path,
          icon: metadata[:icon],
          active: current_path == url_path,
          type: :file,
          children: []
        }
      end

      def filter_index_from_children(children, index_url_path)
        return children unless index_url_path

        children.reject { |child| child[:path] == index_url_path }
      end

      def active_child?(children)
        children.any? do |child|
          child[:active] || active_child?(child[:children] || [])
        end
      end

      def transform_file(item, relative_base)
        file_path = File.join(relative_base, "#{item[:name]}#{Constants::MARKDOWN_EXTENSION}")
        full_file_path = File.join(docs_path, file_path)
        url_path = Utils::PathResolver.to_url(file_path.delete_suffix(Constants::MARKDOWN_EXTENSION))
        metadata = extract_file_metadata(full_file_path)

        {
          title: metadata[:title] || title_extractor.extract(full_file_path),
          path: url_path,
          icon: metadata[:icon],
          active: current_path == url_path,
          type: :file,
          children: []
        }
      end

      def extract_file_metadata(file_path)
        return { title: nil, icon: nil, collapsed: nil } unless File.file?(file_path)

        content = File.read(file_path)
        markdown = Markdown.new(content)
        {
          title: markdown.sidebar_text || markdown.title,
          icon: markdown.sidebar_icon,
          collapsed: markdown.sidebar_collapsed
        }
      rescue StandardError
        { title: nil, icon: nil, collapsed: nil }
      end

      def extract_index_metadata(file_path)
        return { sidebar_text: nil, icon: nil, collapsed: nil } unless File.file?(file_path)

        content = File.read(file_path)
        markdown = Markdown.new(content)
        {
          sidebar_text: markdown.sidebar_text,
          icon: markdown.sidebar_icon,
          collapsed: markdown.sidebar_collapsed
        }
      rescue StandardError
        { sidebar_text: nil, icon: nil, collapsed: nil }
      end
    end
  end
end
