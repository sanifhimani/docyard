# frozen_string_literal: true

require "erb"

module Docyard
  class Renderer
    LAYOUTS_PATH = File.join(__dir__, "templates", "layouts")
    ERRORS_PATH = File.join(__dir__, "templates", "errors")
    PARTIALS_PATH = File.join(__dir__, "templates", "partials")

    attr_reader :layout_path

    def initialize(layout: "default")
      @layout_path = File.join(LAYOUTS_PATH, "#{layout}.html.erb")
    end

    def render_file(file_path, sidebar_html: "", site_title: "Documentation", site_description: "")
      markdown_content = File.read(file_path)
      markdown = Markdown.new(markdown_content)

      html_content = strip_md_from_links(markdown.html)

      render(
        content: html_content,
        page_title: markdown.title || "Documentation",
        sidebar_html: sidebar_html,
        site_title: site_title,
        site_description: site_description
      )
    end

    def render(
      content:,
      page_title: "Documentation",
      sidebar_html: "",
      site_title: "Documentation",
      site_description: ""
    )
      template = File.read(layout_path)

      @content = content
      @page_title = page_title
      @sidebar_html = sidebar_html
      @site_title = site_title
      @site_description = site_description

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

    def render_partial(name, locals = {})
      partial_path = File.join(PARTIALS_PATH, "#{name}.html.erb")
      template = File.read(partial_path)

      locals.each { |key, value| instance_variable_set("@#{key}", value) }

      ERB.new(template).result(binding)
    end

    private

    def strip_md_from_links(html)
      html.gsub(/href="([^"]+)\.md"/, 'href="\1"')
    end
  end
end
