# frozen_string_literal: true

module Docyard
  module Sidebar
    class TitleExtractor
      def extract(file_path)
        return titleize(File.basename(file_path, ".md")) unless File.file?(file_path)

        content = File.read(file_path)
        markdown = Markdown.new(content)
        markdown.title || titleize(File.basename(file_path, ".md"))
      rescue StandardError
        titleize(File.basename(file_path, ".md"))
      end

      private

      def titleize(string)
        return "Home" if string == "index"

        string.gsub(/[-_]/, " ")
              .split
              .map(&:capitalize)
              .join(" ")
      end
    end
  end
end
