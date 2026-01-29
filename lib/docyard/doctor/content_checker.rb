# frozen_string_literal: true

module Docyard
  class Doctor
    class ContentChecker
      FRONTMATTER_REGEX = /\A---\s*\n(.*?\n)---\s*\n/m

      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
      end

      def check
        diagnostics = []
        markdown_files.each do |file|
          diagnostics.concat(check_file(file))
        end
        diagnostics
      end

      private

      def markdown_files
        Dir.glob(File.join(docs_path, "**", "*.md"))
      end

      def check_file(file_path)
        relative_file = file_path.delete_prefix("#{docs_path}/")
        content = File.read(file_path)
        diagnostics = []

        diagnostics.concat(check_frontmatter(content, relative_file))

        diagnostics
      end

      def check_frontmatter(content, relative_file)
        match = content.match(FRONTMATTER_REGEX)
        return [] unless match

        YAML.safe_load(match[1])
        []
      rescue Psych::SyntaxError => e
        [build_frontmatter_diagnostic(relative_file, e)]
      end

      def build_frontmatter_diagnostic(file, error)
        line = error.line ? error.line + 1 : nil

        Diagnostic.new(
          severity: :error,
          category: :CONTENT,
          code: "FRONTMATTER_INVALID_YAML",
          message: "invalid YAML: #{error.problem}",
          file: file,
          line: line
        )
      end
    end
  end
end
