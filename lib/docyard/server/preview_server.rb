# frozen_string_literal: true

require "puma"
require "puma/configuration"
require "puma/launcher"
require "puma/log_writer"
require_relative "../config"
require_relative "static_file_app"

module Docyard
  class PreviewServer
    include Utils::UrlHelpers

    DEFAULT_PORT = 4000

    attr_reader :port, :output_dir, :base_url

    def initialize(port: DEFAULT_PORT)
      @port = port
      @config = Config.load
      @output_dir = File.expand_path(@config.build.output)
      @base_url = normalize_base_url(@config.build.base)
      @launcher = nil
    end

    def start
      validate_output_directory!
      print_server_info
      run_server
    end

    private

    def validate_output_directory!
      unless File.directory?(output_dir)
        abort "#{UI.error('Error:')} #{output_dir}/ directory not found.\n" \
              "Run `docyard build` first to build the site."
      end

      return if Dir.glob(File.join(output_dir, "**", "*")).any? { |f| File.file?(f) }

      abort "#{UI.error('Error:')} #{output_dir}/ is empty.\n" \
            "Run `docyard build` first to build the site."
    end

    def print_server_info
      puts
      puts "  #{UI.bold('Docyard')} v#{Docyard::VERSION}"
      puts
      puts "  Previewing #{output_dir}/"
      puts "  #{UI.cyan("http://localhost:#{port}#{base_url}")}"
      puts
      puts "  #{UI.dim('Press Ctrl+C to stop')}"
      puts
    end

    def run_server
      app = StaticFileApp.new(output_dir, base_path: base_url)
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
