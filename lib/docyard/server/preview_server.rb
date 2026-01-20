# frozen_string_literal: true

require "puma"
require "puma/configuration"
require "puma/launcher"
require "puma/log_writer"
require "rack/mime"
require_relative "../config"

module Docyard
  class PreviewServer
    DEFAULT_PORT = 4000

    attr_reader :port, :output_dir

    def initialize(port: DEFAULT_PORT)
      @port = port
      @config = Config.load
      @output_dir = File.expand_path(@config.build.output)
      @launcher = nil
    end

    def start
      validate_output_directory!
      print_server_info
      run_server
    end

    private

    def validate_output_directory!
      return if File.directory?(output_dir)

      abort "Error: #{output_dir}/ directory not found.\n" \
            "Run `docyard build` first to build the site."
    end

    def print_server_info
      Docyard.logger.info("Starting preview server...")
      Docyard.logger.info("* Version: #{Docyard::VERSION}")
      Docyard.logger.info("* Running at: http://localhost:#{port}")
      Docyard.logger.info("Use Ctrl+C to stop\n")
    end

    def run_server
      app = StaticFileApp.new(output_dir)
      puma_config = build_puma_config(app)
      log_writer = Puma::LogWriter.strings

      @launcher = Puma::Launcher.new(puma_config, log_writer: log_writer)
      @launcher.run
    rescue Interrupt
      Docyard.logger.info("\nShutting down preview server...")
    end

    def build_puma_config(app)
      server_port = port

      Puma::Configuration.new do |config|
        config.bind "tcp://localhost:#{server_port}"
        config.app app
        config.workers 0
        config.threads 1, 4
        config.quiet
      end
    end

    class StaticFileApp
      def initialize(root)
        @root = root
      end

      def call(env)
        path = env["PATH_INFO"]
        file_path = File.join(@root, path)

        if path.end_with?("/") || File.directory?(file_path)
          index_path = File.join(file_path, "index.html")
          return serve_file(index_path) if File.file?(index_path)
        elsif File.file?(file_path)
          return serve_file(file_path)
        end

        serve_not_found
      end

      private

      def serve_file(path)
        content = File.read(path)
        content_type = Rack::Mime.mime_type(File.extname(path), "application/octet-stream")
        [200, { "content-type" => content_type }, [content]]
      end

      def serve_not_found
        error_page = File.join(@root, "404.html")
        if File.file?(error_page)
          [404, { "content-type" => "text/html; charset=utf-8" }, [File.read(error_page)]]
        else
          [404, { "content-type" => "text/plain" }, ["Not Found"]]
        end
      end
    end
  end
end
