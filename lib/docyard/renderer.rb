# frozen_string_literal: true

require "erb"

module Docyard
  class Renderer
    LAYOUTS_PATH = File.join(__dir__, "templates", "layouts")
    ERRORS_PATH = File.join(__dir__, "templates", "errors")

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
      render_error_template(404)
    end

    def render_server_error(error)
      @error_message = error.message
      @backtrace = error.backtrace.join("\n")
      render_error_template(500)
    end

    def render_error_template(status)
      error_template_path = File.join(ERRORS_PATH, "#{status}.html.erb")
      template = File.read(error_template_path)
      ERB.new(template).result(binding)
    end

    private

    def strip_md_from_links(html)
      html.gsub(/href="([^"]+)\.md"/, 'href="\1"')
    end
  end
end
