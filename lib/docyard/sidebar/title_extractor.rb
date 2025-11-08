# frozen_string_literal: true

module Docyard
  module Sidebar
    class TitleExtractor
      def extract(file_path)
        return titleize_filename(file_path) unless File.file?(file_path)

        content = File.read(file_path)
        markdown = Markdown.new(content)
        markdown.title || titleize_filename(file_path)
      rescue StandardError => e
        Docyard.logger.warn "Failed to extract title from #{file_path}: #{e.message}"
        titleize_filename(file_path)
      end

      private

      def titleize_filename(file_path)
        filename = File.basename(file_path, Constants::MARKDOWN_EXTENSION)
        Utils::TextFormatter.titleize(filename)
      end
    end
  end
end
