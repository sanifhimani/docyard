# frozen_string_literal: true

module Docyard
  module Sidebar
    class MetadataExtractor
      attr_reader :docs_path, :title_extractor

      def initialize(docs_path:, title_extractor:)
        @docs_path = docs_path
        @title_extractor = title_extractor
      end

      def extract_index_metadata(file_path)
        return { sidebar_text: nil, icon: nil } unless File.file?(file_path)

        markdown = Markdown.new(File.read(file_path))
        {
          sidebar_text: markdown.sidebar_text,
          icon: markdown.sidebar_icon
        }
      rescue StandardError
        { sidebar_text: nil, icon: nil }
      end

      def extract_frontmatter_metadata(file_path)
        return { text: nil, icon: nil } unless File.exist?(file_path)

        markdown = Markdown.new(File.read(file_path))
        {
          text: markdown.sidebar_text || markdown.title,
          icon: markdown.sidebar_icon
        }
      end

      def extract_file_title(file_path, slug)
        File.exist?(file_path) ? title_extractor.extract(file_path) : Utils::TextFormatter.titleize(slug)
      end

      def extract_common_options(options)
        collapsed_value = options["collapsed"]
        collapsed_value = options[:collapsed] if collapsed_value.nil?
        {
          text: options["text"] || options[:text],
          icon: options["icon"] || options[:icon],
          collapsed: collapsed_value
        }
      end

      def resolve_item_text(slug, file_path, options, frontmatter_text)
        text = options["text"] || options[:text] || frontmatter_text
        text || extract_file_title(file_path, slug)
      end

      def resolve_item_icon(options, frontmatter_icon)
        options["icon"] || options[:icon] || frontmatter_icon
      end
    end
  end
end
