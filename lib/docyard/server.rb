# frozen_string_literal: true

require "webrick"
require "rack"
require "stringio"

module Docyard
  class Server
    DEFAULT_PORT = 4200
    DEFAULT_HOST = "localhost"

    attr_reader :port, :host, :docs_path

    def initialize(port: DEFAULT_PORT, host: DEFAULT_HOST, docs_path: "docs")
      @port = port
      @host = host
      @docs_path = docs_path
    end

    def start
      validate_docs_directory!
      print_server_info

      http_server.mount_proc "/" do |req, res|
        handle_request(req, res)
      end

      trap("INT") { shutdown_server }
      http_server.start
    end

    private

    def validate_docs_directory!
      return if File.directory?(docs_path)

      abort "Error: #{docs_path}/ directory not found.\n" \
            "Run `docyard init` first to create the docs structure."
    end

    def print_server_info
      puts "Starting Docyard server..."
      puts "=> Serving docs from: #{docs_path}/"
      puts "=> Running at: http://#{host}:#{port}"
      puts "=> Press Ctrl+C to stop"
      puts ""
    end

    def http_server
      @http_server ||= WEBrick::HTTPServer.new(
        Port: port,
        BindAddress: host,
        AccessLog: [],
        Logger: WEBrick::Log.new(File::NULL)
      )
    end

    def shutdown_server
      puts "\nShutting down server..."
      http_server.shutdown
    end

    def handle_request(req, res)
      env = build_rack_env(req)
      status, headers, body = app.call(env)

      res.status = status
      headers.each { |key, value| res[key] = value }
      body.each { |chunk| res.body << chunk }
    end

    def build_rack_env(req)
      {
        "REQUEST_METHOD" => req.request_method,
        "PATH_INFO" => req.path,
        "QUERY_STRING" => req.query_string || "",
        "SERVER_NAME" => req.host,
        "SERVER_PORT" => req.port.to_s,
        "rack.version" => Rack::VERSION, "rack.url_scheme" => "http",
        "rack.input" => StringIO.new,
        "rack.errors" => $stderr
      }
    end

    def app
      @app ||= create_rack_app
    end

    def create_rack_app
      expanded_docs_path = File.expand_path(docs_path)
      router = Router.new(docs_path: expanded_docs_path)
      renderer = Renderer.new
      asset_handler = AssetHandler.new

      lambda do |env|
        handle_rack_request(env, asset_handler, router, renderer)
      end
    end

    def handle_rack_request(env, asset_handler, router, renderer)
      path = env["PATH_INFO"]
      return asset_handler.serve(path) if path.start_with?("/assets/")

      file_path = router.resolve(path)
      status = file_path ? 200 : 404
      html = file_path ? renderer.render_file(file_path) : renderer.render_not_found
      [status, { "Content-Type" => "text/html; charset=utf-8" }, [html]]
    rescue StandardError => e
      [500, { "Content-Type" => "text/html; charset=utf-8" }, [build_error_html(e)]]
    end

    def build_error_html(error)
      <<~HTML
        <html>
          <head><title>500 - Server Error</title></head>
          <body>
            <h1>500 - Internal Server Error</h1>
            <pre>#{error.message}</pre>
            <h3>Backtrace:</h3>
            <pre>#{error.backtrace.join("\n")}</pre>
          </body>
        </html>
      HTML
    end
  end
end
