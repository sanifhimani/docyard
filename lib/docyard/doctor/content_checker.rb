# frozen_string_literal: true

module Docyard
  class Doctor
    class ContentChecker
      FRONTMATTER_REGEX = /\A---\s*\n(.*?\n)---\s*\n/m
      INCLUDE_PATTERN = /<!--\s*@include:\s*([^\s]+)\s*-->/
      CODE_FENCE_REGEX = /^(`{3,}|~{3,})/
      MARKDOWN_EXTENSIONS = %w[.md .markdown .mdx].freeze

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
        diagnostics.concat(check_includes(content, file_path, relative_file))

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

      def check_includes(content, file_path, relative_file)
        diagnostics = []

        each_line_outside_code_blocks(content) do |line_content, line_number|
          line_content.scan(INCLUDE_PATTERN) do
            include_path = Regexp.last_match[1]
            diagnostic = validate_include(include_path, file_path, relative_file, line_number)
            diagnostics << diagnostic if diagnostic
          end
        end

        diagnostics
      end

      def each_line_outside_code_blocks(content)
        in_code_block = false

        content.each_line.with_index(1) do |line, line_number|
          in_code_block = !in_code_block if line.match?(CODE_FENCE_REGEX)
          yield(line, line_number) unless in_code_block
        end
      end

      def validate_include(include_path, file_path, relative_file, line_number)
        full_path = resolve_include_path(include_path, file_path)

        unless full_path && File.exist?(full_path)
          return build_include_diagnostic(relative_file, line_number, include_path, "file not found")
        end

        unless markdown_file?(include_path)
          return build_include_diagnostic(relative_file, line_number, include_path, "non-markdown file")
        end

        nil
      end

      def resolve_include_path(include_path, current_file)
        if include_path.start_with?("./", "../")
          base_dir = File.dirname(current_file)
          File.expand_path(include_path, base_dir)
        else
          File.join(docs_path, include_path)
        end
      end

      def markdown_file?(filepath)
        ext = File.extname(filepath).downcase
        MARKDOWN_EXTENSIONS.include?(ext)
      end

      def build_include_diagnostic(file, line, include_path, message)
        Diagnostic.new(
          severity: :error,
          category: :CONTENT,
          code: "INCLUDE_ERROR",
          message: "include '#{include_path}': #{message}",
          file: file,
          line: line
        )
      end
    end
  end
end
