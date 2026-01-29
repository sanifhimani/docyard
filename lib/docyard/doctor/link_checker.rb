# frozen_string_literal: true

module Docyard
  class Doctor
    class LinkChecker
      MARKDOWN_LINK_REGEX = /\[([^\]]*)\]\(([^)]+)\)/
      INTERNAL_LINK_REGEX = %r{^/[^/]}
      IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .gif .svg .webp .ico .bmp].freeze
      CODE_FENCE_REGEX = /^(`{3,}|~{3,})/

      attr_reader :docs_path, :files_checked, :links_checked

      def initialize(docs_path)
        @docs_path = docs_path
        @files_checked = 0
        @links_checked = 0
      end

      def check
        diagnostics = []
        files = markdown_files
        @files_checked = files.size
        files.each { |file| diagnostics.concat(check_file(file)) }
        diagnostics
      end

      private

      def markdown_files
        Dir.glob(File.join(docs_path, "**", "*.md"))
      end

      def check_file(file_path)
        relative_file = file_path.delete_prefix("#{docs_path}/")
        diagnostics = []

        each_line_outside_code_blocks(file_path) do |line, line_number|
          diagnostics.concat(check_line_for_links(line, line_number, relative_file))
        end

        diagnostics
      end

      def each_line_outside_code_blocks(file_path)
        content = File.read(file_path)
        in_code_block = false

        content.each_line.with_index(1) do |line, line_number|
          in_code_block = !in_code_block if line.match?(CODE_FENCE_REGEX)
          yield(line, line_number) unless in_code_block
        end
      end

      def check_line_for_links(line, line_number, relative_file)
        diagnostics = []
        line.scan(MARKDOWN_LINK_REGEX) do |_text, url|
          next unless internal_link?(url)
          next if image_path?(url)

          @links_checked += 1
          target_path = url.split("#").first
          next if file_exists?(target_path)

          diagnostics << build_diagnostic(relative_file, line_number, target_path)
        end
        diagnostics
      end

      def build_diagnostic(file, line, target)
        Diagnostic.new(
          severity: :error,
          category: :LINK,
          code: "LINK_BROKEN",
          message: target,
          file: file,
          line: line
        )
      end

      def internal_link?(url)
        url.match?(INTERNAL_LINK_REGEX)
      end

      def image_path?(url)
        IMAGE_EXTENSIONS.any? { |ext| url.downcase.end_with?(ext) }
      end

      def file_exists?(url_path)
        clean_path = url_path.chomp("/")
        possible_files = [
          File.join(docs_path, "#{clean_path}.md"),
          File.join(docs_path, clean_path, "index.md"),
          File.join(docs_path, "#{clean_path}.html")
        ]
        possible_files.any? { |f| File.exist?(f) }
      end
    end
  end
end
