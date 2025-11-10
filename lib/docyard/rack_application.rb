# frozen_string_literal: true

require "json"
require "rack"
require_relative "sidebar_builder"
require_relative "constants"

module Docyard
  class RackApplication
    def initialize(docs_path:, file_watcher:, config: nil)
      @docs_path = docs_path
      @file_watcher = file_watcher
      @config = config
      @router = Router.new(docs_path: docs_path)
      @renderer = Renderer.new
      @asset_handler = AssetHandler.new
    end

    def call(env)
      handle_request(env)
    end

    private

    attr_reader :docs_path, :file_watcher, :config, :router, :renderer, :asset_handler

    def handle_request(env)
      path = env["PATH_INFO"]

      return handle_reload_check(env) if path == Constants::RELOAD_ENDPOINT
      return asset_handler.serve(path) if path.start_with?(Constants::ASSETS_PREFIX)

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
      html = renderer.render_file(
        file_path,
        sidebar_html: build_sidebar(current_path),
        branding: branding_options
      )

      [Constants::STATUS_OK, { "Content-Type" => Constants::CONTENT_TYPE_HTML }, [html]]
    end

    def render_not_found_page
      html = renderer.render_not_found
      [Constants::STATUS_NOT_FOUND, { "Content-Type" => Constants::CONTENT_TYPE_HTML }, [html]]
    end

    def build_sidebar(current_path)
      SidebarBuilder.new(
        docs_path: docs_path,
        current_path: current_path,
        config: config
      ).to_html
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
      site = config.site
      branding = config.branding

      {
        site_title: site.title || Constants::DEFAULT_SITE_TITLE,
        site_description: site.description || "",
        logo: resolve_logo(branding.logo, branding.logo_dark),
        logo_dark: resolve_logo_dark(branding.logo, branding.logo_dark),
        favicon: branding.favicon
      }.merge(appearance_options(branding.appearance))
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
  end
end
