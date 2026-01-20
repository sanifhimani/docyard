# frozen_string_literal: true

require "puma"
require "puma/configuration"
require "puma/launcher"
require "puma/log_writer"
require_relative "../config"
require_relative "static_file_app"

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
  end
end
