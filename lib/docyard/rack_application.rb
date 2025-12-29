# frozen_string_literal: true

require "json"
require "rack"
require_relative "sidebar_builder"
require_relative "prev_next_builder"
require_relative "constants"

module Docyard
  class RackApplication
    PAGEFIND_CONTENT_TYPES = {
      ".js" => "application/javascript; charset=utf-8",
      ".css" => "text/css; charset=utf-8",
      ".json" => "application/json; charset=utf-8"
    }.freeze

    def initialize(docs_path:, file_watcher:, config: nil, pagefind_path: nil)
      @docs_path = docs_path
      @file_watcher = file_watcher
      @config = config
      @pagefind_path = pagefind_path
      @router = Router.new(docs_path: docs_path)
      @renderer = Renderer.new(base_url: config&.build&.base_url || "/", config: config)
      @asset_handler = AssetHandler.new
    end

    def call(env)
      handle_request(env)
    end

    private

    attr_reader :docs_path, :file_watcher, :config, :pagefind_path, :router, :renderer, :asset_handler

    def handle_request(env)
      path = env["PATH_INFO"]

      return handle_reload_check(env) if path == Constants::RELOAD_ENDPOINT
      return asset_handler.serve(path) if path.start_with?(Constants::ASSETS_PREFIX)
      return serve_pagefind(path) if path.start_with?(Constants::PAGEFIND_PREFIX)

      handle_documentation_request(path)
    rescue StandardError => e
      handle_error(e)
    end

    def handle_documentation_request(path)
      result = router.resolve(path)

      if result.found?
        render_documentation_page(result.file_path, path)
      else
        render_not_found_page
      end
    end

    def render_documentation_page(file_path, current_path)
      sidebar_builder = build_sidebar_instance(current_path)

      html = renderer.render_file(
        file_path,
        sidebar_html: sidebar_builder.to_html,
        prev_next_html: build_prev_next(sidebar_builder, current_path, file_path),
        branding: branding_options
      )

      [Constants::STATUS_OK, { "Content-Type" => Constants::CONTENT_TYPE_HTML }, [html]]
    end

    def render_not_found_page
      html = renderer.render_not_found
      [Constants::STATUS_NOT_FOUND, { "Content-Type" => Constants::CONTENT_TYPE_HTML }, [html]]
    end

    def build_sidebar_instance(current_path)
      SidebarBuilder.new(
        docs_path: docs_path,
        current_path: current_path,
        config: config
      )
    end

    def build_prev_next(sidebar_builder, current_path, file_path)
      markdown_content = File.read(file_path)
      markdown = Markdown.new(markdown_content)

      PrevNextBuilder.new(
        sidebar_tree: sidebar_builder.tree,
        current_path: current_path,
        frontmatter: markdown.frontmatter,
        config: navigation_config
      ).to_html
    end

    def navigation_config
      return {} unless config

      config.navigation&.footer || {}
    end

    def branding_options
      return default_branding unless config

      default_branding.merge(config_branding_options)
    end

    def default_branding
      {
        site_title: Constants::DEFAULT_SITE_TITLE,
        site_description: "",
        logo: Constants::DEFAULT_LOGO_PATH,
        logo_dark: Constants::DEFAULT_LOGO_DARK_PATH,
        favicon: nil,
        display_logo: true,
        display_title: true
      }
    end

    def config_branding_options
      site_options.merge(logo_options).merge(search_options).merge(appearance_options(config.branding.appearance))
    end

    def site_options
      {
        site_title: config.site.title || Constants::DEFAULT_SITE_TITLE,
        site_description: config.site.description || "",
        favicon: config.branding.favicon
      }
    end

    def logo_options
      branding = config.branding
      {
        logo: resolve_logo(branding.logo, branding.logo_dark),
        logo_dark: resolve_logo_dark(branding.logo, branding.logo_dark)
      }
    end

    def search_options
      {
        search_enabled: config.search.enabled != false,
        search_placeholder: config.search.placeholder || "Search documentation..."
      }
    end

    def appearance_options(appearance)
      appearance ||= {}
      {
        display_logo: appearance["logo"] != false,
        display_title: appearance["title"] != false
      }
    end

    def resolve_logo(logo, logo_dark)
      logo || logo_dark || Constants::DEFAULT_LOGO_PATH
    end

    def resolve_logo_dark(logo, logo_dark)
      logo_dark || logo || Constants::DEFAULT_LOGO_DARK_PATH
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

    def serve_pagefind(path)
      relative_path = path.delete_prefix(Constants::PAGEFIND_PREFIX)
      return pagefind_not_found if relative_path.include?("..")

      file_path = resolve_pagefind_file(relative_path)
      return pagefind_not_found unless file_path && File.file?(file_path)

      content = File.binread(file_path)
      content_type = pagefind_content_type(file_path)

      headers = {
        "Content-Type" => content_type,
        "Cache-Control" => "no-cache, no-store, must-revalidate",
        "Pragma" => "no-cache",
        "Expires" => "0"
      }

      [Constants::STATUS_OK, headers, [content]]
    end

    def resolve_pagefind_file(relative_path)
      return File.join(pagefind_path, relative_path) if pagefind_path && Dir.exist?(pagefind_path)

      output_dir = config&.build&.output_dir || "dist"
      File.join(output_dir, "pagefind", relative_path)
    end

    def pagefind_content_type(file_path)
      extension = File.extname(file_path)
      PAGEFIND_CONTENT_TYPES.fetch(extension, "application/octet-stream")
    end

    def pagefind_not_found
      message = "Pagefind not found. Run 'docyard build' first."
      [Constants::STATUS_NOT_FOUND, { "Content-Type" => "text/plain" }, [message]]
    end
  end
end
