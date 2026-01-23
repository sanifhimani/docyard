# frozen_string_literal: true

require "erb"
require_relative "../constants"
require_relative "../utils/git_info"
require_relative "icon_helpers"
require_relative "og_helpers"
require_relative "branding_variables"

module Docyard
  class Renderer
    include Utils::UrlHelpers
    include Utils::HtmlHelpers
    include IconHelpers
    include OgHelpers
    include BrandingVariables

    LAYOUTS_PATH = File.join(__dir__, "../templates", "layouts")
    ERRORS_PATH = File.join(__dir__, "../templates", "errors")
    PARTIALS_PATH = File.join(__dir__, "../templates", "partials")
    DEFAULT_LAYOUT = "default"

    attr_reader :base_url, :config, :dev_mode, :sse_port

    def initialize(base_url: "/", config: nil, dev_mode: false, sse_port: nil)
      @base_url = normalize_base_url(base_url)
      @config = config
      @dev_mode = dev_mode
      @sse_port = sse_port
    end

    def render_file(file_path, sidebar_html: "", prev_next_html: "", breadcrumbs: nil, branding: {},
                    template_options: {}, current_path: "/")
      raw_content = File.read(file_path)
      markdown = Markdown.new(raw_content, config: config, file_path: file_path)

      render(
        content: strip_md_from_links(markdown.html),
        page_title: markdown.title || Constants::DEFAULT_SITE_TITLE,
        page_description: markdown.description,
        page_og_image: markdown.og_image,
        navigation: build_navigation(sidebar_html, prev_next_html, markdown.toc, breadcrumbs),
        branding: branding,
        template_options: template_options,
        current_path: current_path,
        file_path: file_path,
        raw_markdown: raw_content
      )
    end

    def render_for_search(file_path)
      markdown = Markdown.new(File.read(file_path), config: config, file_path: file_path)
      title = markdown.title || Constants::DEFAULT_SITE_TITLE
      content = strip_md_from_links(markdown.html)

      <<~HTML
        <!DOCTYPE html>
        <html>
        <head><title>#{escape_html(title)}</title></head>
        <body><main data-pagefind-body>#{content}</main></body>
        </html>
      HTML
    end

    def build_navigation(sidebar_html, prev_next_html, toc, breadcrumbs)
      { sidebar_html: sidebar_html, prev_next_html: prev_next_html, toc: toc, breadcrumbs: breadcrumbs }
    end

    def render(content:, page_title: Constants::DEFAULT_SITE_TITLE, page_description: nil, page_og_image: nil,
               navigation: {}, branding: {}, template_options: {}, current_path: "/", file_path: nil,
               raw_markdown: nil)
      layout = template_options[:template] || DEFAULT_LAYOUT
      layout_path = File.join(LAYOUTS_PATH, "#{layout}.html.erb")
      template = File.read(layout_path)

      assign_content_variables(content, page_title, navigation, raw_markdown)
      assign_branding_variables(branding, current_path)
      assign_og_variables(branding, page_description, page_og_image, current_path)
      assign_template_variables(template_options)
      assign_git_info(branding, file_path)
      assign_feedback_variables

      ERB.new(template).result(binding)
    end

    def render_not_found(branding: nil)
      @primary_color = branding&.dig(:primary_color)
      render_error_template(404)
    end

    def render_server_error(error, branding: nil)
      @error_message = error.message
      @backtrace = error.backtrace&.join("\n") || "No backtrace available"
      @primary_color = branding&.dig(:primary_color)
      render_error_template(500)
    end

    def render_error_template(status)
      error_template_path = File.join(ERRORS_PATH, "#{status}.html.erb")
      template = File.read(error_template_path)
      ERB.new(template).result(binding)
    end

    VALID_IVAR_PATTERN = /\A[a-z_][a-z0-9_]*\z/i

    def render_partial(name, locals = {})
      partial_path = File.join(PARTIALS_PATH, "#{name}.html.erb")
      template = File.read(partial_path)

      locals.each do |key, value|
        validate_variable_name!(key)
        instance_variable_set("@#{key}", value)
      end

      ERB.new(template).result(binding)
    end

    def render_custom_visual(file_path)
      return "" if file_path.nil? || file_path.empty?

      source_dir = config&.source || "docs"
      full_path = File.join(source_dir, file_path)

      return "" unless File.exist?(full_path)

      File.read(full_path)
    end

    def validate_variable_name!(name)
      return if name.to_s.match?(VALID_IVAR_PATTERN)

      raise ArgumentError, "Invalid variable name: #{name}"
    end

    def asset_path(path)
      return path if path.nil? || path.start_with?("http://", "https://")

      "#{base_url}#{path}"
    end

    private

    def assign_content_variables(content, page_title, navigation, raw_markdown)
      @content = content
      @page_title = page_title
      @sidebar_html = navigation[:sidebar_html] || ""
      @prev_next_html = navigation[:prev_next_html] || ""
      @toc = navigation[:toc] || []
      @breadcrumbs = navigation[:breadcrumbs]
      @raw_markdown = raw_markdown
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

    def assign_feedback_variables
      return unless config

      @feedback_enabled = config.feedback.enabled
      @feedback_question = config.feedback.question
    end
  end
end
