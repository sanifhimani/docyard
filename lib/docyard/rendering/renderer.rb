# frozen_string_literal: true

require "erb"
require_relative "../config/constants"
require_relative "../utils/git_info"
require_relative "icon_helpers"
require_relative "og_helpers"

module Docyard
  class Renderer
    include Utils::UrlHelpers
    include IconHelpers
    include OgHelpers

    LAYOUTS_PATH = File.join(__dir__, "../templates", "layouts")
    ERRORS_PATH = File.join(__dir__, "../templates", "errors")
    PARTIALS_PATH = File.join(__dir__, "../templates", "partials")
    DEFAULT_LAYOUT = "default"

    attr_reader :base_url, :config

    def initialize(base_url: "/", config: nil)
      @base_url = normalize_base_url(base_url)
      @config = config
    end

    def render_file(file_path, sidebar_html: "", prev_next_html: "", breadcrumbs: nil, branding: {},
                    template_options: {}, current_path: "/")
      markdown = Markdown.new(File.read(file_path), config: config, file_path: file_path)

      render(
        content: strip_md_from_links(markdown.html),
        page_title: markdown.title || Constants::DEFAULT_SITE_TITLE,
        page_description: markdown.description,
        page_og_image: markdown.og_image,
        navigation: build_navigation(sidebar_html, prev_next_html, markdown.toc, breadcrumbs),
        branding: branding,
        template_options: template_options,
        current_path: current_path,
        file_path: file_path
      )
    end

    def build_navigation(sidebar_html, prev_next_html, toc, breadcrumbs)
      { sidebar_html: sidebar_html, prev_next_html: prev_next_html, toc: toc, breadcrumbs: breadcrumbs }
    end

    def render(content:, page_title: Constants::DEFAULT_SITE_TITLE, page_description: nil, page_og_image: nil,
               navigation: {}, branding: {}, template_options: {}, current_path: "/", file_path: nil)
      layout = template_options[:template] || DEFAULT_LAYOUT
      layout_path = File.join(LAYOUTS_PATH, "#{layout}.html.erb")
      template = File.read(layout_path)

      assign_content_variables(content, page_title, navigation)
      assign_branding_variables(branding, current_path)
      assign_og_variables(branding, page_description, page_og_image, current_path)
      assign_template_variables(template_options)
      assign_git_info(branding, file_path)

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

    def assign_content_variables(content, page_title, navigation)
      @content = content
      @page_title = page_title
      @sidebar_html = navigation[:sidebar_html] || ""
      @prev_next_html = navigation[:prev_next_html] || ""
      @toc = navigation[:toc] || []
      @breadcrumbs = navigation[:breadcrumbs]
    end

    def assign_branding_variables(branding, current_path = "/")
      assign_site_branding(branding)
      assign_search_options(branding)
      assign_credits_and_social(branding)
      assign_tabs(branding, current_path)
      assign_analytics(branding)
    end

    def assign_site_branding(branding)
      @site_title = branding[:site_title] || Constants::DEFAULT_SITE_TITLE
      @site_description = branding[:site_description] || ""
      @logo = branding[:logo] || Constants::DEFAULT_LOGO_PATH
      @logo_dark = branding[:logo_dark]
      @favicon = branding[:favicon] || Constants::DEFAULT_FAVICON_PATH
      @has_custom_logo = branding[:has_custom_logo] || false
    end

    def assign_search_options(branding)
      @search_enabled = branding[:search_enabled].nil? || branding[:search_enabled]
      @search_placeholder = branding[:search_placeholder] || "Search documentation..."
    end

    def assign_credits_and_social(branding)
      @credits = branding[:credits] != false
      @copyright = branding[:copyright]
      @social = branding[:social] || []
      @header_ctas = branding[:header_ctas] || []
      @announcement = branding[:announcement]
    end

    def assign_analytics(branding)
      @has_analytics = branding[:has_analytics] || false
      @analytics_google = branding[:analytics_google]
      @analytics_plausible = branding[:analytics_plausible]
      @analytics_fathom = branding[:analytics_fathom]
      @analytics_script = branding[:analytics_script]
    end

    def assign_tabs(branding, current_path)
      tabs = branding[:tabs] || []
      @tabs = tabs.map { |tab| tab.merge(active: tab_active?(tab[:href], current_path)) }
      @has_tabs = branding[:has_tabs] || false
      @current_path = current_path
    end

    def tab_active?(tab_href, current_path)
      return false if tab_href.nil? || current_path.nil?
      return false if tab_href.start_with?("http://", "https://")

      normalized_tab = tab_href.chomp("/")
      normalized_current = current_path.chomp("/")

      return true if normalized_tab == normalized_current

      current_path.start_with?("#{normalized_tab}/")
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

    def assign_git_info(branding, file_path)
      @show_edit_link = branding[:show_edit_link] && file_path
      @show_last_updated = branding[:show_last_updated] && file_path
      return unless @show_edit_link || @show_last_updated

      git_info = Utils::GitInfo.new(
        repo_url: branding[:repo_url],
        branch: branding[:repo_branch],
        edit_path: branding[:repo_edit_path]
      )

      @edit_url = git_info.edit_url(file_path) if @show_edit_link
      @last_updated = git_info.last_updated(file_path) if @show_last_updated
    end
  end
end
