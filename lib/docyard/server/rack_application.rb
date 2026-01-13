# frozen_string_literal: true

require "json"
require "rack"
require_relative "../navigation/sidebar_builder"
require_relative "../navigation/prev_next_builder"
require_relative "../config/branding_resolver"
require_relative "../config/constants"
require_relative "../rendering/template_resolver"
require_relative "../routing/fallback_resolver"
require_relative "pagefind_handler"

module Docyard
  class RackApplication
    def initialize(docs_path:, file_watcher:, config: nil, pagefind_path: nil)
      @docs_path = docs_path
      @file_watcher = file_watcher
      @config = config
      @router = Router.new(docs_path: docs_path)
      @renderer = Renderer.new(base_url: config&.build&.base || "/", config: config)
      @asset_handler = AssetHandler.new
      @pagefind_handler = PagefindHandler.new(pagefind_path: pagefind_path, config: config)
    end

    def call(env)
      handle_request(env)
    end

    private

    attr_reader :docs_path, :file_watcher, :config, :router, :renderer, :asset_handler, :pagefind_handler

    def handle_request(env)
      path = env["PATH_INFO"]

      return handle_reload_check(env) if path == Constants::RELOAD_ENDPOINT
      return asset_handler.serve_docyard_assets(path) if path.start_with?(Constants::DOCYARD_ASSETS_PREFIX)
      return pagefind_handler.serve(path) if path.start_with?(Constants::PAGEFIND_PREFIX)

      public_response = asset_handler.serve_public_file(path)
      return public_response if public_response

      handle_documentation_request(path)
    rescue StandardError => e
      handle_error(e)
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
                                                           template_options: template_resolver.to_options)

      [Constants::STATUS_OK, { "Content-Type" => Constants::CONTENT_TYPE_HTML }, [html]]
    end

    def build_navigation_html(template_resolver, current_path, markdown, header_ctas)
      return { sidebar_html: "", prev_next_html: "" } unless template_resolver.show_sidebar?

      sidebar_builder = build_sidebar_instance(current_path, header_ctas)
      { sidebar_html: sidebar_builder.to_html,
        prev_next_html: build_prev_next(sidebar_builder, current_path, markdown) }
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
        header_ctas: header_ctas
      )
    end

    def build_prev_next(sidebar_builder, current_path, markdown)
      PrevNextBuilder.new(
        sidebar_tree: sidebar_builder.tree,
        current_path: current_path,
        frontmatter: markdown.frontmatter,
        config: navigation_config
      ).to_html
    end

    def navigation_config
      {}
    end

    def branding_options
      BrandingResolver.new(config).resolve
    end

    def handle_reload_check(env)
      since = parse_since_timestamp(env)
      reload_needed = file_watcher.changed_since?(since)

      build_reload_response(reload_needed)
    rescue StandardError => e
      log_reload_error(e)
      build_reload_response(false)
    end

    def parse_since_timestamp(env)
      query = Rack::Utils.parse_query(env["QUERY_STRING"])
      query["since"] ? Time.at(query["since"].to_f) : Time.now
    end

    def log_reload_error(error)
      Docyard.logger.error "Reload check error: #{error.message}"
      Docyard.logger.debug error.backtrace.join("\n")
    end

    def build_reload_response(reload_needed)
      response_body = { reload: reload_needed, timestamp: Time.now.to_f }.to_json
      [Constants::STATUS_OK, { "Content-Type" => Constants::CONTENT_TYPE_JSON }, [response_body]]
    end

    def handle_error(error)
      Docyard.logger.error "Request error: #{error.message}"
      Docyard.logger.debug error.backtrace.join("\n")
      [Constants::STATUS_INTERNAL_ERROR, { "Content-Type" => Constants::CONTENT_TYPE_HTML },
       [renderer.render_server_error(error)]]
    end
  end
end
