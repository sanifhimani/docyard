# frozen_string_literal: true

require "puma"
require "puma/configuration"
require "puma/launcher"
require "puma/log_writer"
require_relative "rack_application"
require_relative "../config"

module Docyard
  class Server
    DEFAULT_PORT = 4200
    DEFAULT_HOST = "localhost"

    attr_reader :port, :host, :docs_path, :config, :search_enabled

    def initialize(port: DEFAULT_PORT, host: DEFAULT_HOST, docs_path: "docs", search: false)
      @port = port
      @host = host
      @docs_path = docs_path
      @search_enabled = search
      @config = Config.load
      @search_indexer = nil
      @launcher = nil
    end

    def start
      validate_docs_directory!
      generate_search_index if @search_enabled
      print_server_info
      run_server
    ensure
      cleanup
    end

    private

    def generate_search_index
      @search_indexer = Search::DevIndexer.new(
        docs_path: File.expand_path(docs_path),
        config: @config
      )
      @search_indexer.generate
    end

    def cleanup
      @search_indexer&.cleanup
    end

    def validate_docs_directory!
      return if File.directory?(docs_path)

      abort "Error: #{docs_path}/ directory not found.\n" \
            "Run `docyard init` first to create the docs structure."
    end

    def print_server_info
      puts "Starting Docyard server..."
      puts "* Version: #{Docyard::VERSION}"
      puts "* Running at: http://#{host}:#{port}"
      puts "* Search: #{@search_enabled ? 'enabled' : 'disabled (use --search to enable)'}"
      puts "Use Ctrl+C to stop\n"
    end

    def run_server
      app = build_rack_app
      puma_config = build_puma_config(app)
      log_writer = Puma::LogWriter.strings

      @launcher = Puma::Launcher.new(puma_config, log_writer: log_writer)
      @launcher.run
    rescue Interrupt
      puts "\nShutting down server..."
    end

    def build_rack_app
      RackApplication.new(
        docs_path: File.expand_path(docs_path),
        config: @config,
        pagefind_path: @search_indexer&.pagefind_path
      )
    end

    def build_puma_config(app)
      server_host = host
      server_port = port

      Puma::Configuration.new do |config|
        config.bind "tcp://#{server_host}:#{server_port}"
        config.app app
        config.workers 0
        config.threads 1, 4
        config.quiet
      end
    end
  end
end
