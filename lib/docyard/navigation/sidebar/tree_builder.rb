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
        transform_items(file_items, "")
      end

      private

      def transform_items(items, relative_base)
        items.map do |item|
          if item[:type] == :directory
            transform_directory(item, relative_base)
          else
            transform_file(item, relative_base)
          end
        end
      end

      def transform_directory(item, relative_base)
        dir_path = File.join(relative_base, item[:name])
        children = transform_items(item[:children], dir_path)

        {
          title: Utils::TextFormatter.titleize(item[:name]),
          path: nil,
          active: false,
          type: :directory,
          collapsible: true,
          collapsed: !active_child?(children),
          children: children
        }
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
        return { title: nil, icon: nil } unless File.file?(file_path)

        content = File.read(file_path)
        markdown = Markdown.new(content)
        {
          title: markdown.sidebar_text || markdown.title,
          icon: markdown.sidebar_icon
        }
      rescue StandardError
        { title: nil, icon: nil }
      end
    end
  end
end
