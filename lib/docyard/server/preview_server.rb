# frozen_string_literal: true

require "webrick"
require_relative "../config"

module Docyard
  class PreviewServer
    DEFAULT_PORT = 4000

    attr_reader :port, :output_dir

    def initialize(port: DEFAULT_PORT)
      @port = port
      @config = Config.load
      @output_dir = File.expand_path(@config.build.output_dir)
    end

    def start
      validate_output_directory!
      print_server_info

      server = create_server
      trap("INT") { shutdown_server(server) }

      server.start
    end

    private

    def validate_output_directory!
      return if File.directory?(output_dir)

      abort "Error: #{output_dir}/ directory not found.\n" \
            "Run `docyard build` first to build the site."
    end

    def print_server_info
      puts "Preview server starting..."
      puts "=> Serving from: #{output_dir}/"
      puts "=> Running at: http://localhost:#{port}"
      puts "=> Press Ctrl+C to stop\n"
    end

    def create_server
      WEBrick::HTTPServer.new(
        Port: port,
        DocumentRoot: output_dir,
        AccessLog: [],
        Logger: WEBrick::Log.new(File::NULL),
        MimeTypes: mime_types
      )
    end

    def mime_types
      WEBrick::HTTPUtils::DefaultMimeTypes.merge(
        {
          "css" => "text/css",
          "js" => "application/javascript",
          "json" => "application/json",
          "svg" => "image/svg+xml",
          "woff" => "font/woff",
          "woff2" => "font/woff2"
        }
      )
    end

    def shutdown_server(server)
      puts "\nShutting down preview server..."
      server.shutdown
    end
  end
end
