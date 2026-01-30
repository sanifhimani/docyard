# frozen_string_literal: true

require_relative "../diagnostic_context"

module Docyard
  class Doctor
    class SidebarChecker
      SIDEBAR_DOCS_URL = "https://docyard.dev/customize/sidebar/"

      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
        @sidebar_path = File.join(docs_path, "_sidebar.yml")
      end

      def check
        loader = Sidebar::LocalConfigLoader.new(docs_path, validate: false)
        items = loader.load
        diagnostics = convert_key_errors(loader.key_errors)
        diagnostics.concat(check_missing_files(items)) if items
        diagnostics
      end

      private

      def convert_key_errors(key_errors)
        key_errors.map do |error|
          Diagnostic.new(
            severity: :error,
            category: :SIDEBAR,
            code: "SIDEBAR_VALIDATION",
            field: "_sidebar.yml: #{error[:context]}",
            message: error[:message],
            fix: error[:fix]
          )
        end
      end

      def check_missing_files(items, path_prefix: "")
        diagnostics = []
        items.each do |item|
          diagnostics.concat(check_item_file(item, path_prefix))
        end
        diagnostics
      end

      def check_item_file(item, path_prefix)
        diagnostics = []
        slug, options = extract_slug_and_options(item)
        return diagnostics unless slug

        if requires_file?(options)
          file_path = build_file_path(path_prefix, slug, options)
          diagnostics << build_missing_file_diagnostic(slug, path_prefix, file_path) unless file_exists?(file_path)
        end

        if options.is_a?(Hash) && options["items"]
          nested_prefix = options["group"] ? path_prefix : File.join(path_prefix, slug)
          diagnostics.concat(check_missing_files(options["items"], path_prefix: nested_prefix))
        end

        diagnostics
      end

      def requires_file?(options)
        return true unless options.is_a?(Hash)
        return true unless options["items"]

        options["index"]
      end

      def extract_slug_and_options(item)
        return [item, nil] if item.is_a?(String)
        return [nil, nil] unless item.is_a?(Hash)
        return [nil, nil] if external_link?(item)
        return [nil, nil] if item.keys.size != 1

        slug = item.keys.first
        slug.is_a?(String) ? [slug, item[slug]] : [nil, nil]
      end

      def build_file_path(path_prefix, slug, options)
        base = File.join(path_prefix, slug)
        options.is_a?(Hash) && options["index"] ? File.join(base, "index") : base
      end

      def file_exists?(relative_path)
        md_path = File.join(docs_path, "#{relative_path}.md")
        index_path = File.join(docs_path, relative_path, "index.md")
        File.exist?(md_path) || File.exist?(index_path)
      end

      def build_missing_file_diagnostic(slug, path_prefix, file_path)
        context = path_prefix.empty? ? slug : "#{path_prefix}/#{slug}"
        line = find_sidebar_line(slug)
        source_context = DiagnosticContext.extract_source_context(@sidebar_path, line) if line

        Diagnostic.new(
          severity: :error,
          category: :SIDEBAR,
          code: "SIDEBAR_MISSING_FILE",
          file: "_sidebar.yml",
          line: line,
          field: context,
          message: "references missing file '#{file_path}.md'",
          doc_url: SIDEBAR_DOCS_URL,
          source_context: source_context
        )
      end

      def find_sidebar_line(slug)
        return nil unless File.exist?(@sidebar_path)

        lines = File.readlines(@sidebar_path)
        lines.each_with_index do |line, index|
          return index + 1 if line.include?("- #{slug}") || line.include?("#{slug}:")
        end
        nil
      end

      def external_link?(item)
        item.key?("link") || item.key?(:link)
      end
    end
  end
end
