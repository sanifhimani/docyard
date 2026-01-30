# frozen_string_literal: true

require_relative "../diagnostic_context"

module Docyard
  class Doctor
    class LinkChecker
      MARKDOWN_LINK_REGEX = /\[([^\]]*)\]\(([^)]+)\)/
      INTERNAL_LINK_REGEX = %r{^/[^/]}
      IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .gif .svg .webp .ico .bmp].freeze
      CODE_FENCE_REGEX = /^(`{3,}|~{3,})/
      LINKS_DOCS_URL = nil

      attr_reader :docs_path, :links_checked

      def initialize(docs_path)
        @docs_path = docs_path
        @links_checked = 0
      end

      def check_file(content, file_path)
        relative_file = file_path.delete_prefix("#{docs_path}/")
        diagnostics = []

        each_line_outside_code_blocks(content) do |line, line_number|
          diagnostics.concat(check_line_for_links(line, line_number, relative_file))
        end

        diagnostics
      end

      private

      def each_line_outside_code_blocks(content)
        in_code_block = false

        content.each_line.with_index(1) do |line, line_number|
          in_code_block = !in_code_block if line.match?(CODE_FENCE_REGEX)
          yield(line, line_number) unless in_code_block
        end
      end

      def check_line_for_links(line, line_number, relative_file)
        line.scan(MARKDOWN_LINK_REGEX).filter_map do |_text, url|
          next unless internal_link?(url)
          next if image_path?(url)

          @links_checked += 1
          target_path = url.split("#").first
          next if file_exists?(target_path)

          build_diagnostic(relative_file, line_number, target_path)
        end
      end

      def build_diagnostic(file, line, target)
        full_path = File.join(docs_path, file)
        source_context = DiagnosticContext.extract_source_context(full_path, line)

        Diagnostic.new(
          severity: :warning,
          category: :LINK,
          code: "LINK_BROKEN",
          message: "Broken link to '#{target}'",
          file: file,
          line: line,
          field: target,
          doc_url: LINKS_DOCS_URL,
          source_context: source_context
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
        [
          File.join(docs_path, "#{clean_path}.md"),
          File.join(docs_path, clean_path, "index.md"),
          File.join(docs_path, "#{clean_path}.html")
        ].any? { |f| File.exist?(f) }
      end
    end
  end
end
