# frozen_string_literal: true

require "json"
require "rack"
require_relative "sidebar_builder"

module Docyard
  class RackApplication
    def initialize(docs_path:, file_watcher:)
      @docs_path = docs_path
      @file_watcher = file_watcher
      @router = Router.new(docs_path: docs_path)
      @renderer = Renderer.new
      @asset_handler = AssetHandler.new
    end

    def call(env)
      handle_request(env)
    end

    private

    attr_reader :docs_path, :file_watcher, :router, :renderer, :asset_handler

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
        sidebar = SidebarBuilder.new(docs_path: docs_path, current_path: path)
        html = renderer.render_file(result.file_path, sidebar_html: sidebar.to_html)
        [Constants::STATUS_OK, { "Content-Type" => Constants::CONTENT_TYPE_HTML }, [html]]
      else
        html = renderer.render_not_found
        [Constants::STATUS_NOT_FOUND, { "Content-Type" => Constants::CONTENT_TYPE_HTML }, [html]]
      end
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
