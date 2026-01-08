# frozen_string_literal: true

module Docyard
  module Sidebar
    class MetadataReader
      def extract_file_metadata(file_path)
        return empty_file_metadata unless File.file?(file_path)

        content = File.read(file_path)
        markdown = Markdown.new(content)
        {
          title: markdown.sidebar_text || markdown.title,
          icon: markdown.sidebar_icon,
          collapsed: markdown.sidebar_collapsed,
          order: markdown.sidebar_order
        }
      rescue StandardError
        empty_file_metadata
      end

      def extract_index_metadata(file_path)
        return empty_index_metadata unless File.file?(file_path)

        content = File.read(file_path)
        markdown = Markdown.new(content)
        {
          sidebar_text: markdown.sidebar_text,
          icon: markdown.sidebar_icon,
          collapsed: markdown.sidebar_collapsed,
          order: markdown.sidebar_order
        }
      rescue StandardError
        empty_index_metadata
      end

      private

      def empty_file_metadata
        { title: nil, icon: nil, collapsed: nil, order: nil }
      end

      def empty_index_metadata
        { sidebar_text: nil, icon: nil, collapsed: nil, order: nil }
      end
    end
  end
end
