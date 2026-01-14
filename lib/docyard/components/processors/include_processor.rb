# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      class IncludeProcessor < BaseProcessor
        INCLUDE_PATTERN = /<!--\s*@include:\s*([^\s]+)\s*-->/

        self.priority = 0

        def preprocess(content)
          @current_file = context[:current_file]
          @docs_root = context[:docs_root] || "docs"
          @included_files = Set.new

          process_includes(content)
        end

        private

        def process_includes(content)
          content.gsub(INCLUDE_PATTERN) { |_| process_include(Regexp.last_match) }
        end

        def process_include(match)
          filepath = match[1]
          full_path = resolve_path(filepath)

          error = validate_include(filepath, full_path)
          return error if error

          @included_files.add(full_path)
          file_content = File.read(full_path)

          process_includes(file_content.strip)
        end

        def validate_include(filepath, full_path)
          return include_error(filepath, "File not found") unless full_path && File.exist?(full_path)
          return include_error(filepath, "Circular include detected") if @included_files.include?(full_path)
          return include_error(filepath, "Use code snippets for non-markdown files") unless markdown_file?(filepath)

          nil
        end

        def resolve_path(filepath)
          if filepath.start_with?("./", "../")
            resolve_relative_path(filepath)
          else
            resolve_docs_path(filepath)
          end
        end

        def resolve_relative_path(filepath)
          return nil unless @current_file

          base_dir = File.dirname(@current_file)
          full_path = File.expand_path(filepath, base_dir)

          full_path if File.exist?(full_path)
        end

        def resolve_docs_path(filepath)
          full_path = File.join(@docs_root, filepath)
          full_path if File.exist?(full_path)
        end

        def markdown_file?(filepath)
          ext = File.extname(filepath).downcase
          %w[.md .markdown .mdx].include?(ext)
        end

        def include_error(filepath, message)
          "> [!WARNING]\n> Include error: #{filepath} - #{message}\n"
        end
      end
    end
  end
end
