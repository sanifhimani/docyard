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

      return handle_reload_check(env) if path == "/_docyard/reload"
      return asset_handler.serve(path) if path.start_with?("/assets/")

      handle_documentation_request(path)
    rescue StandardError => e
      handle_error(e)
    end

    def handle_documentation_request(path)
      file_path = router.resolve(path)
      status = file_path ? 200 : 404

      if file_path
        sidebar = SidebarBuilder.new(docs_path: docs_path, current_path: path)
        sidebar_html = sidebar.to_html

        html = renderer.render_file(file_path, sidebar_html: sidebar_html)
      else
        html = renderer.render_not_found
      end

      [status, { "Content-Type" => "text/html; charset=utf-8" }, [html]]
    end

    def handle_reload_check(env)
      query = Rack::Utils.parse_query(env["QUERY_STRING"])
      since = query["since"] ? Time.at(query["since"].to_f) : Time.now
      reload_needed = file_watcher.changed_since?(since)

      build_reload_response(reload_needed)
    rescue StandardError => e
      puts "[Docyard] Reload check error: #{e.message}"
      build_reload_response(false)
    end

    def build_reload_response(reload_needed)
      response_body = { reload: reload_needed, timestamp: Time.now.to_f }.to_json
      [200, { "Content-Type" => "application/json" }, [response_body]]
    end

    def handle_error(error)
      [500, { "Content-Type" => "text/html; charset=utf-8" }, [renderer.render_server_error(error)]]
    end
  end
end
