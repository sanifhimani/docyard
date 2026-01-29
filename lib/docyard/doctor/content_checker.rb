# frozen_string_literal: true

module Docyard
  class Doctor
    class ContentChecker
      FRONTMATTER_REGEX = /\A---\s*\n(.*?\n)---\s*\n/m
      INCLUDE_PATTERN = /<!--\s*@include:\s*([^\s]+)\s*-->/
      SNIPPET_PATTERN = %r{^<<<\s+@/([^\s{#]+)(?:#([\w-]+))?(?:\{([^}]+)\})?\s*$}
      CODE_FENCE_REGEX = /^(`{3,}|~{3,})/
      MARKDOWN_EXTENSIONS = %w[.md .markdown .mdx].freeze

      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
      end

      def check_file(content, file_path)
        relative_file = file_path.delete_prefix("#{docs_path}/")

        [
          check_frontmatter(content, relative_file),
          check_includes(content, file_path, relative_file),
          check_snippets(content, relative_file)
        ].flatten
      end

      private

      def check_frontmatter(content, relative_file)
        match = content.match(FRONTMATTER_REGEX)
        return [] unless match

        YAML.safe_load(match[1])
        []
      rescue Psych::SyntaxError => e
        [build_frontmatter_diagnostic(relative_file, e)]
      end

      def build_frontmatter_diagnostic(file, error)
        Diagnostic.new(
          severity: :error,
          category: :CONTENT,
          code: "FRONTMATTER_INVALID_YAML",
          message: "invalid YAML: #{error.problem}",
          file: file,
          line: error.line ? error.line + 1 : nil
        )
      end

      def check_includes(content, file_path, relative_file)
        each_line_outside_code_blocks(content).filter_map do |line_content, line_number|
          match = line_content.match(INCLUDE_PATTERN)
          next unless match

          validate_include(match[1], file_path, relative_file, line_number)
        end
      end

      def each_line_outside_code_blocks(content)
        return enum_for(__method__, content) unless block_given?

        in_code_block = false
        content.each_line.with_index(1) do |line, line_number|
          in_code_block = !in_code_block if line.match?(CODE_FENCE_REGEX)
          yield(line, line_number) unless in_code_block
        end
      end

      def validate_include(include_path, file_path, relative_file, line_number)
        full_path = resolve_include_path(include_path, file_path)

        unless file_exists?(full_path)
          return build_include_diagnostic(relative_file, line_number, include_path,
                                          "file not found")
        end
        unless markdown_file?(include_path)
          return build_include_diagnostic(relative_file, line_number, include_path,
                                          "non-markdown file")
        end

        nil
      end

      def file_exists?(path)
        path && File.exist?(path)
      end

      def resolve_include_path(include_path, current_file)
        if include_path.start_with?("./", "../")
          File.expand_path(include_path, File.dirname(current_file))
        else
          File.join(docs_path, include_path)
        end
      end

      def markdown_file?(filepath)
        MARKDOWN_EXTENSIONS.include?(File.extname(filepath).downcase)
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

      def check_snippets(content, relative_file)
        each_line_outside_code_blocks(content).filter_map do |line_content, line_number|
          match = line_content.match(SNIPPET_PATTERN)
          next unless match

          validate_snippet(match, relative_file, line_number)
        end
      end

      def validate_snippet(match, relative_file, line_number)
        filepath = match[1]
        region = match[2]
        full_path = File.join(docs_path, filepath)

        unless File.exist?(full_path)
          return build_snippet_diagnostic(relative_file, line_number, filepath,
                                          "file not found")
        end
        if region && !region_exists?(
          full_path, region
        )
          return build_snippet_diagnostic(relative_file, line_number, filepath,
                                          "region '#{region}' not found")
        end

        nil
      end

      def region_exists?(file_path, region_name)
        content = File.read(file_path)
        content.match?(%r{^[ \t]*(?://|#|/\*)\s*#region\s+#{Regexp.escape(region_name)}\b})
      end

      def build_snippet_diagnostic(file, line, snippet_path, message)
        Diagnostic.new(
          severity: :error,
          category: :CONTENT,
          code: "SNIPPET_ERROR",
          message: "snippet '#{snippet_path}': #{message}",
          file: file,
          line: line
        )
      end
    end
  end
end
