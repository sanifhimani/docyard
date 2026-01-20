# frozen_string_literal: true

require_relative "../rendering/markdown"

module Docyard
  module Build
    class LlmsTxtGenerator
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def generate
        pages = collect_pages.sort_by { |page| page[:path] }
        generate_llms_txt(pages)
        generate_llms_full_txt(pages)
      end

      private

      def collect_pages
        Dir.glob(File.join(config.source, "**", "*.md")).map { |f| build_page_data(f) }
      end

      def build_page_data(file_path)
        content = File.read(file_path)
        markdown = Markdown.new(content, config: config, file_path: file_path)

        {
          title: markdown.title || url_path_for(file_path),
          description: markdown.description,
          path: url_path_for(file_path),
          content: strip_frontmatter(content)
        }
      end

      def url_path_for(file_path)
        relative = file_path.delete_prefix("#{config.source}/").delete_suffix(".md")
        relative == "index" ? "/" : "/#{relative}"
      end

      def strip_frontmatter(content)
        return content unless content.start_with?("---")

        parts = content.split(/^---\s*$/, 3)
        parts.length >= 3 ? parts[2].strip : content
      end

      def generate_llms_txt(pages)
        output_path = File.join(config.build.output, "llms.txt")
        File.write(output_path, build_llms_txt_content(pages))
        Docyard.logger.info("[✓] Generated llms.txt (#{pages.size} pages)")
      end

      def build_llms_txt_content(pages)
        lines = header_lines
        lines << "## Docs"
        lines << ""
        lines.concat(pages.map { |page| format_page_link(page) })
        lines.join("\n")
      end

      def format_page_link(page)
        line = "- [#{page[:title]}](#{page_url(page[:path])})"
        line += ": #{page[:description]}" if page[:description]&.length&.positive?
        line
      end

      def generate_llms_full_txt(pages)
        output_path = File.join(config.build.output, "llms-full.txt")
        File.write(output_path, build_llms_full_txt_content(pages))
        Docyard.logger.info("[✓] Generated llms-full.txt")
      end

      def build_llms_full_txt_content(pages)
        lines = header_lines
        lines << "This file contains the complete documentation content."
        lines << ""
        pages.each { |page| lines.concat(format_page_content(page)) }
        lines.join("\n")
      end

      def format_page_content(page)
        ["---", "", "## #{page[:title]}", "", "URL: #{page_url(page[:path])}", "", page[:content], ""]
      end

      def header_lines
        lines = ["# #{config.title}", ""]
        return lines unless config.description&.length&.positive?

        lines << "> #{config.description}"
        lines << ""
        lines
      end

      def page_url(path)
        base = config.url || config.build.base
        "#{base.chomp('/')}#{path}"
      end
    end
  end
end
