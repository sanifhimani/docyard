# frozen_string_literal: true

require "json"
require "rack"
require_relative "../navigation/page_navigation_builder"
require_relative "../navigation/sidebar_builder"
require_relative "../config/branding_resolver"
require_relative "../constants"
require_relative "../rendering/template_resolver"
require_relative "../routing/fallback_resolver"
require_relative "pagefind_handler"

module Docyard
  class RackApplication
    def initialize(docs_path:, config: nil, pagefind_path: nil, sse_port: nil, sidebar_cache: nil)
      @docs_path = docs_path
      @config = config
      @sse_port = sse_port
      @dev_mode = !sse_port.nil?
      @sidebar_cache = sidebar_cache
      @router = Router.new(docs_path: docs_path)
      @renderer = Renderer.new(base_url: "/", config: config, dev_mode: @dev_mode,
                               sse_port: sse_port)
      @asset_handler = AssetHandler.new(public_dir: config&.public_dir || "docs/public")
      @pagefind_handler = PagefindHandler.new(pagefind_path: pagefind_path, config: config)
    end

    def call(env)
      handle_request(env)
    end

    private

    attr_reader :docs_path, :config, :router, :renderer, :asset_handler, :pagefind_handler, :dev_mode

    def handle_request(env)
      path = env["PATH_INFO"]

      return pagefind_handler.serve(path) if path.start_with?(Constants::PAGEFIND_PREFIX)
      return asset_handler.serve_docyard_assets(path) if path.start_with?(Constants::DOCYARD_ASSETS_PREFIX)

      public_response = asset_handler.serve_public_file(path)
      return public_response if public_response

      handle_documentation_request(path)
    rescue StandardError => e
      handle_error(e, env)
    end

    def handle_documentation_request(path)
      if root_path?(path)
        html_response = serve_custom_landing_page
        return html_response if html_response
      end

      result = router.resolve(path)

      if result.found?
        render_documentation_page(result.file_path, path)
      else
        try_fallback_redirect(path)
      end
    end

    def root_path?(path)
      path == "/" || path.empty?
    end

    def serve_custom_landing_page
      html_path = File.join(docs_path, "index.html")
      return nil unless File.file?(html_path)

      html = File.read(html_path)
      [Constants::STATUS_OK, { "Content-Type" => Constants::CONTENT_TYPE_HTML }, [html]]
    end

    def try_fallback_redirect(path)
      sidebar_builder = build_sidebar_instance(path)
      fallback_resolver = Routing::FallbackResolver.new(
        docs_path: docs_path,
        sidebar_builder: sidebar_builder
      )

      fallback_path = fallback_resolver.resolve_fallback(path)
      if fallback_path
        redirect_to(fallback_path)
      else
        render_not_found_page
      end
    end

    def redirect_to(path)
      [Constants::STATUS_REDIRECT, { "Location" => path }, []]
    end

    def render_documentation_page(file_path, current_path)
      markdown = Markdown.new(File.read(file_path))
      template_resolver = TemplateResolver.new(markdown.frontmatter, @config&.data)
      branding = branding_options

      navigation = build_navigation_html(template_resolver, current_path, markdown, branding[:header_ctas])
      html = renderer.render_file(file_path, **navigation, branding: branding,
                                                           template_options: template_resolver.to_options,
                                                           current_path: current_path)

      [Constants::STATUS_OK, { "Content-Type" => Constants::CONTENT_TYPE_HTML }, [html]]
    end

    def build_navigation_html(template_resolver, current_path, markdown, header_ctas)
      navigation_builder.build(
        current_path: current_path,
        markdown: markdown,
        header_ctas: header_ctas,
        show_sidebar: template_resolver.show_sidebar?
      )
    end

    def navigation_builder
      @navigation_builder ||= Navigation::PageNavigationBuilder.new(
        docs_path: docs_path,
        config: config,
        sidebar_cache: @sidebar_cache
      )
    end

    def render_not_found_page
      html = renderer.render_not_found
      [Constants::STATUS_NOT_FOUND, { "Content-Type" => Constants::CONTENT_TYPE_HTML }, [html]]
    end

    def build_sidebar_instance(current_path, header_ctas = [])
      SidebarBuilder.new(
        docs_path: docs_path,
        current_path: current_path,
        config: config,
        header_ctas: header_ctas,
        sidebar_cache: @sidebar_cache
      )
    end

    def branding_options
      BrandingResolver.new(config).resolve
    end

    def handle_error(error, env)
      request_context = build_request_context(env)
      Docyard.logger.error("Request error: #{error.message} [#{request_context}]")
      Docyard.logger.debug(error.backtrace.join("\n"))
      [Constants::STATUS_INTERNAL_ERROR, { "Content-Type" => Constants::CONTENT_TYPE_HTML },
       [renderer.render_server_error(error)]]
    end

    def build_request_context(env)
      method = env["REQUEST_METHOD"]
      path = env["PATH_INFO"]
      user_agent = env["HTTP_USER_AGENT"]&.slice(0, 50)
      user_agent ? "#{method} #{path} - #{user_agent}" : "#{method} #{path}"
    end
  end
end
