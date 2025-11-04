# frozen_string_literal: true

require "erb"

module Docyard
  class Renderer
    LAYOUTS_PATH = File.join(__dir__, "templates", "layouts")

    attr_reader :layout_path

    def initialize(layout: "default")
      @layout_path = File.join(LAYOUTS_PATH, "#{layout}.html.erb")
    end

    def render_file(file_path)
      markdown_content = File.read(file_path)
      markdown = Markdown.new(markdown_content)

      html_content = strip_md_from_links(markdown.html)

      render(
        content: html_content,
        page_title: markdown.title || "Documentation"
      )
    end

    def render(content:, page_title: "Documentation")
      template = File.read(layout_path)

      @content = content
      @page_title = page_title

      ERB.new(template).result(binding)
    end

    def render_not_found
      render(
        content: "<h1>404 - Page Not Found</h1><p>The page you're looking for doesn't exist.</p>",
        page_title: "404 - Not Found"
      )
    end

    private

    def strip_md_from_links(html)
      html.gsub(/href="([^"]+)\.md"/, 'href="\1"')
    end
  end
end
