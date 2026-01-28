# frozen_string_literal: true

require "thor"

module Docyard
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "version", "Show docyard version"
    def version
      puts "docyard #{Docyard::VERSION}"
    end

    desc "init [PROJECT_NAME]", "Initialize a new docyard project"
    method_option :force, type: :boolean, default: false, aliases: "-f",
                          desc: "Overwrite existing files"
    def init(project_name = nil)
      initializer = Docyard::Initializer.new(project_name, force: options[:force])
      exit(1) unless initializer.run
    end

    desc "build", "Build static site for production"
    method_option :clean, type: :boolean, default: true, desc: "Clean output directory before building"
    method_option :verbose, type: :boolean, default: false, aliases: "-v", desc: "Show verbose output"
    def build
      require_relative "builder"
      builder = Docyard::Builder.new(
        clean: options[:clean],
        verbose: options[:verbose]
      )
      exit(1) unless builder.build
    rescue ConfigError => e
      Docyard.logger.error(e.message)
      exit(1)
    end

    desc "preview", "Preview the built site locally"
    method_option :port, type: :numeric, default: 4000, aliases: "-p", desc: "Port to run preview server on"
    def preview
      require_relative "server/preview_server"
      Docyard::PreviewServer.new(port: options[:port]).start
    end

    desc "serve", "Start the development server"
    method_option :port, type: :numeric, default: 4200, aliases: "-p", desc: "Port to run the server on"
    method_option :host, type: :string, default: "localhost", aliases: "-h", desc: "Host to bind the server to"
    method_option :search, type: :boolean, default: false, aliases: "-s",
                           desc: "Enable search indexing (slower startup)"
    def serve
      require_relative "server/dev_server"
      config = Docyard::Config.load
      server = Docyard::DevServer.new(
        port: options[:port],
        host: options[:host],
        docs_path: config.source,
        search: options[:search]
      )
      server.start
    rescue ConfigError => e
      Docyard.logger.error(e.message)
      exit(1)
    end

    desc "doctor", "Check documentation for issues"
    def doctor
      require_relative "doctor"
      doctor = Docyard::Doctor.new
      exit(doctor.run)
    rescue ConfigError => e
      Docyard.logger.error(e.message)
      exit(1)
    end
  end
end
