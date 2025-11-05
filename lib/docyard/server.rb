# frozen_string_literal: true

require "webrick"
require "stringio"
require_relative "file_watcher"
require_relative "rack_application"

module Docyard
  class Server
    DEFAULT_PORT = 4200
    DEFAULT_HOST = "localhost"

    attr_reader :port, :host, :docs_path

    def initialize(port: DEFAULT_PORT, host: DEFAULT_HOST, docs_path: "docs")
      @port = port
      @host = host
      @docs_path = docs_path
      @file_watcher = FileWatcher.new(File.expand_path(docs_path))
      @app = RackApplication.new(
        docs_path: File.expand_path(docs_path),
        file_watcher: @file_watcher
      )
    end

    def start
      validate_docs_directory!
      print_server_info
      @file_watcher.start

      http_server.mount_proc("/") { |req, res| handle_request(req, res) }
      trap("INT") { shutdown_server }

      http_server.start
      @file_watcher.stop
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
      puts "=> Press Ctrl+C to stop\n"
    end

    def shutdown_server
      puts "\nShutting down server..."
      http_server.shutdown
    end

    def http_server
      @http_server ||= WEBrick::HTTPServer.new(
        Port: port,
        BindAddress: host,
        AccessLog: [],
        Logger: WEBrick::Log.new(File::NULL)
      )
    end

    def handle_request(req, res)
      env = build_rack_env(req)
      status, headers, body = @app.call(env)

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
        "rack.version" => Rack::VERSION,
        "rack.url_scheme" => "http",
        "rack.input" => StringIO.new,
        "rack.errors" => $stderr
      }
    end
  end
end
