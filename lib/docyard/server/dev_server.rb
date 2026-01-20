# frozen_string_literal: true

require "puma"
require "puma/configuration"
require "puma/launcher"
require "puma/log_writer"
require_relative "rack_application"
require_relative "sse_server"
require_relative "file_watcher"
require_relative "../config"
require_relative "../navigation/sidebar/cache"

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
      @sse_server = nil
      @file_watcher = nil
      @launcher = nil
      @sidebar_cache = nil
    end

    def start
      validate_docs_directory!
      build_sidebar_cache
      generate_search_index if @search_enabled
      setup_hot_reload
      print_server_info
      run_server
    ensure
      cleanup
    end

    private

    def build_sidebar_cache
      @sidebar_cache = Sidebar::Cache.new(
        docs_path: File.expand_path(docs_path),
        config: @config
      )
      @sidebar_cache.build
    end

    def generate_search_index
      @search_indexer = Search::DevIndexer.new(
        docs_path: File.expand_path(docs_path),
        config: @config
      )
      @search_indexer.generate
    end

    def setup_hot_reload
      @sse_server = SSEServer.new(port: sse_port)
      @sse_server.start

      @file_watcher = FileWatcher.new(
        docs_path: docs_path,
        on_change: ->(change_type) { handle_file_change(change_type) }
      )
      @file_watcher.start
    end

    def sse_port
      port + 1
    end

    def handle_file_change(change_type)
      invalidate_sidebar_cache if change_type == :full
      log_file_change(change_type)
      @sse_server.broadcast("reload", { type: change_type.to_s })
    end

    def invalidate_sidebar_cache
      @sidebar_cache&.invalidate
      @sidebar_cache&.build
    end

    def log_file_change(change_type)
      message = case change_type
                when :content then "Content changed, reloading..."
                when :config then "Config changed, full reload..."
                when :asset then "Asset changed, reloading..."
                else "File changed, reloading..."
                end
      Docyard.logger.info("* #{message}")
    end

    def cleanup
      @file_watcher&.stop
      @sse_server&.stop
      @search_indexer&.cleanup
    end

    def validate_docs_directory!
      return if File.directory?(docs_path)

      abort "Error: #{docs_path}/ directory not found.\n" \
            "Run `docyard init` first to create the docs structure."
    end

    def print_server_info
      Docyard.logger.info("Starting Docyard server...")
      Docyard.logger.info("* Version: #{Docyard::VERSION}")
      Docyard.logger.info("* Running at: http://#{host}:#{port}")
      Docyard.logger.info("* Hot reload: ws://127.0.0.1:#{sse_port}")
      Docyard.logger.info("* Search: #{@search_enabled ? 'enabled' : 'disabled (use --search to enable)'}")
      Docyard.logger.info("Use Ctrl+C to stop\n")
    end

    def run_server
      app = build_rack_app
      puma_config = build_puma_config(app)
      log_writer = Puma::LogWriter.strings

      @launcher = Puma::Launcher.new(puma_config, log_writer: log_writer)
      @launcher.run
    end

    def build_rack_app
      RackApplication.new(
        docs_path: File.expand_path(docs_path),
        config: @config,
        pagefind_path: @search_indexer&.pagefind_path,
        sse_port: sse_port,
        sidebar_cache: @sidebar_cache
      )
    end

    def build_puma_config(app)
      server_host = host
      server_port = port

      Puma::Configuration.new do |config|
        config.bind "tcp://#{server_host}:#{server_port}"
        config.app app
        config.workers 0
        config.threads 4, 8
        config.quiet
      end
    end
  end
end
