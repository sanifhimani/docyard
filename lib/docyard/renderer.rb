# frozen_string_literal: true

require "erb"
require_relative "constants"

module Docyard
  class Renderer
    LAYOUTS_PATH = File.join(__dir__, "templates", "layouts")
    ERRORS_PATH = File.join(__dir__, "templates", "errors")
    PARTIALS_PATH = File.join(__dir__, "templates", "partials")

    attr_reader :layout_path, :base_url

    def initialize(layout: "default", base_url: "/")
      @layout_path = File.join(LAYOUTS_PATH, "#{layout}.html.erb")
      @base_url = normalize_base_url(base_url)
    end

    def render_file(file_path, sidebar_html: "", branding: {})
      markdown_content = File.read(file_path)
      markdown = Markdown.new(markdown_content)

      html_content = strip_md_from_links(markdown.html)

      render(
        content: html_content,
        page_title: markdown.title || Constants::DEFAULT_SITE_TITLE,
        sidebar_html: sidebar_html,
        branding: branding
      )
    end

    def render(content:, page_title: Constants::DEFAULT_SITE_TITLE, sidebar_html: "", branding: {})
      template = File.read(layout_path)

      assign_content_variables(content, page_title, sidebar_html)
      assign_branding_variables(branding)

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

    def asset_path(path)
      return path if path.nil? || path.start_with?("http://", "https://")

      "#{base_url}#{path}"
    end

    def link_path(path)
      return path if path.nil? || path.start_with?("http://", "https://")

      "#{base_url.chomp('/')}#{path}"
    end

    private

    def normalize_base_url(url)
      return "/" if url.nil? || url.empty?

      url = "/#{url}" unless url.start_with?("/")
      url.end_with?("/") ? url : "#{url}/"
    end

    def assign_content_variables(content, page_title, sidebar_html)
      @content = content
      @page_title = page_title
      @sidebar_html = sidebar_html
    end

    def assign_branding_variables(branding)
      @site_title = branding[:site_title] || Constants::DEFAULT_SITE_TITLE
      @site_description = branding[:site_description] || ""
      @logo = branding[:logo] || Constants::DEFAULT_LOGO_PATH
      @logo_dark = branding[:logo_dark]
      @favicon = branding[:favicon] || Constants::DEFAULT_FAVICON_PATH
      @display_logo = branding[:display_logo].nil? || branding[:display_logo]
      @display_title = branding[:display_title].nil? || branding[:display_title]
    end

    def strip_md_from_links(html)
      html.gsub(/href="([^"]+)\.md"/, 'href="\1"')
    end
  end
end
