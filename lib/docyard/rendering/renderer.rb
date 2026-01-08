# frozen_string_literal: true

require "erb"
require_relative "../config/constants"
require_relative "icon_helpers"

module Docyard
  class Renderer
    include Utils::UrlHelpers
    include IconHelpers

    LAYOUTS_PATH = File.join(__dir__, "../templates", "layouts")
    ERRORS_PATH = File.join(__dir__, "../templates", "errors")
    PARTIALS_PATH = File.join(__dir__, "../templates", "partials")
    DEFAULT_LAYOUT = "default"

    attr_reader :base_url, :config

    def initialize(base_url: "/", config: nil)
      @base_url = normalize_base_url(base_url)
      @config = config
    end

    def render_file(file_path, sidebar_html: "", prev_next_html: "", branding: {}, template_options: {})
      markdown_content = File.read(file_path)
      markdown = Markdown.new(markdown_content, config: config)

      html_content = strip_md_from_links(markdown.html)
      toc = markdown.toc

      render(
        content: html_content,
        page_title: markdown.title || Constants::DEFAULT_SITE_TITLE,
        navigation: {
          sidebar_html: sidebar_html,
          prev_next_html: prev_next_html,
          toc: toc
        },
        branding: branding,
        template_options: template_options
      )
    end

    def render(content:, page_title: Constants::DEFAULT_SITE_TITLE, navigation: {}, branding: {}, template_options: {})
      layout = template_options[:template] || DEFAULT_LAYOUT
      layout_path = File.join(LAYOUTS_PATH, "#{layout}.html.erb")
      template = File.read(layout_path)

      sidebar_html = navigation[:sidebar_html] || ""
      prev_next_html = navigation[:prev_next_html] || ""
      toc = navigation[:toc] || []

      assign_content_variables(content, page_title, sidebar_html, prev_next_html, toc)
      assign_branding_variables(branding)
      assign_template_variables(template_options)

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

    private

    def assign_content_variables(content, page_title, sidebar_html, prev_next_html, toc)
      @content = content
      @page_title = page_title
      @sidebar_html = sidebar_html
      @prev_next_html = prev_next_html
      @toc = toc
    end

    def assign_branding_variables(branding)
      assign_site_branding(branding)
      assign_display_options(branding)
      assign_search_options(branding)
      assign_credits_and_social(branding)
    end

    def assign_site_branding(branding)
      @site_title = branding[:site_title] || Constants::DEFAULT_SITE_TITLE
      @site_description = branding[:site_description] || ""
      @logo = branding[:logo] || Constants::DEFAULT_LOGO_PATH
      @logo_dark = branding[:logo_dark]
      @favicon = branding[:favicon] || Constants::DEFAULT_FAVICON_PATH
    end

    def assign_display_options(branding)
      @display_logo = branding[:display_logo].nil? || branding[:display_logo]
      @display_title = branding[:display_title].nil? || branding[:display_title]
    end

    def assign_search_options(branding)
      @search_enabled = branding[:search_enabled].nil? || branding[:search_enabled]
      @search_placeholder = branding[:search_placeholder] || "Search documentation..."
    end

    def assign_credits_and_social(branding)
      @credits = branding[:credits] != false
      @social = branding[:social] || []
    end

    def assign_template_variables(template_options)
      @hero = template_options[:hero]
      @features = template_options[:features]
      @features_header = template_options[:features_header]
      @show_sidebar = template_options.fetch(:show_sidebar, true)
      @show_toc = template_options.fetch(:show_toc, true)
      assign_footer_from_landing(template_options[:footer])
    end

    def assign_footer_from_landing(footer)
      return unless footer

      @footer_links = footer[:links]
    end

    def strip_md_from_links(html)
      html.gsub(/href="([^"]+)\.md"/, 'href="\1"')
    end
  end
end
