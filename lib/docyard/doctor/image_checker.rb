# frozen_string_literal: true

require_relative "issue"

module Docyard
  class Doctor
    class ImageChecker
      MARKDOWN_IMAGE_REGEX = /!\[([^\]]*)\]\(([^)]+)\)/
      HTML_IMAGE_REGEX = /<img[^>]+src=["']([^"']+)["']/
      CODE_FENCE_REGEX = /^(`{3,}|~{3,})/

      attr_reader :docs_path, :images_checked

      def initialize(docs_path)
        @docs_path = docs_path
        @images_checked = 0
      end

      def check
        issues = []
        markdown_files.each do |file|
          issues.concat(check_file(file))
        end
        issues
      end

      private

      def markdown_files
        Dir.glob(File.join(docs_path, "**", "*.md"))
      end

      def check_file(file_path)
        relative_file = file_path.delete_prefix("#{docs_path}/")
        file_dir = File.dirname(file_path)
        issues = []

        each_line_outside_code_blocks(file_path) do |line, line_number|
          issues.concat(check_line_for_images(line, line_number, relative_file, file_dir))
        end

        issues
      end

      def each_line_outside_code_blocks(file_path)
        content = File.read(file_path)
        in_code_block = false

        content.each_line.with_index(1) do |line, line_number|
          in_code_block = !in_code_block if line.match?(CODE_FENCE_REGEX)
          yield(line, line_number) unless in_code_block
        end
      end

      def check_line_for_images(line, line_number, relative_file, file_dir)
        extract_image_paths(line).filter_map do |image_path|
          next if external_url?(image_path)

          @images_checked += 1
          next if image_exists?(image_path, file_dir)

          Issue.new(file: relative_file, line: line_number, target: image_path)
        end
      end

      def extract_image_paths(line)
        paths = []
        line.scan(MARKDOWN_IMAGE_REGEX) { |_alt, src| paths << src }
        line.scan(HTML_IMAGE_REGEX) { |src| paths << src.first }
        paths
      end

      def external_url?(path)
        path.start_with?("http://", "https://", "//")
      end

      def image_exists?(image_path, file_dir)
        if image_path.start_with?("/")
          absolute_image_exists?(image_path)
        else
          relative_image_exists?(image_path, file_dir)
        end
      end

      def absolute_image_exists?(image_path)
        clean_path = image_path.delete_prefix("/")
        possible_locations = [
          File.join(docs_path, clean_path),
          File.join(docs_path, "public", clean_path)
        ]
        possible_locations.any? { |f| File.exist?(f) }
      end

      def relative_image_exists?(image_path, file_dir)
        full_path = File.expand_path(image_path, file_dir)
        File.exist?(full_path)
      end
    end
  end
end
