# frozen_string_literal: true

require "thor"

module Docyard
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    class_option :no_color, type: :boolean, default: false, desc: "Disable colored output"

    desc "version", "Show docyard version"
    def version
      puts "docyard #{Docyard::VERSION}"
    end

    desc "init [PROJECT_NAME]", "Initialize a new docyard project"
    method_option :force, type: :boolean, default: false, aliases: "-f",
                          desc: "Overwrite existing files"
    def init(project_name = nil)
      apply_global_options
      initializer = Docyard::Initializer.new(project_name, force: options[:force])
      exit(1) unless initializer.run
    end

    desc "build", "Build static site for production"
    method_option :clean, type: :boolean, default: true, desc: "Clean output directory before building"
    method_option :verbose, type: :boolean, default: false, aliases: "-v", desc: "Show verbose output"
    method_option :strict, type: :boolean, default: false, desc: "Fail on any validation errors"
    def build
      apply_global_options
      require_relative "builder"
      builder = Docyard::Builder.new(
        clean: options[:clean],
        verbose: options[:verbose],
        strict: options[:strict]
      )
      exit(1) unless builder.build
    rescue ConfigError => e
      print_config_error(e)
    end

    desc "preview", "Preview the built site locally"
    method_option :port, type: :numeric, default: 4000, aliases: "-p", desc: "Port to run preview server on"
    def preview
      apply_global_options
      require_relative "server/preview_server"
      Docyard::PreviewServer.new(port: options[:port]).start
    rescue ConfigError => e
      print_config_error(e)
    end

    desc "serve", "Start the development server"
    method_option :port, type: :numeric, default: 4200, aliases: "-p", desc: "Port to run the server on"
    method_option :host, type: :string, default: "localhost", aliases: "-h", desc: "Host to bind the server to"
    method_option :search, type: :boolean, default: false, aliases: "-s",
                           desc: "Enable search indexing (slower startup)"
    def serve
      apply_global_options
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
      print_config_error(e)
    end

    desc "doctor", "Check documentation for issues"
    method_option :fix, type: :boolean, default: false, desc: "Auto-fix fixable issues"
    def doctor
      apply_global_options
      require_relative "doctor"
      doctor = Docyard::Doctor.new(fix: options[:fix])
      exit(doctor.run)
    end

    desc "customize", "Generate theme customization files"
    method_option :minimal, type: :boolean, default: false, aliases: "-m",
                            desc: "Generate minimal files without comments"
    def customize
      apply_global_options
      require_relative "customizer"
      Docyard::Customizer.new(minimal: options[:minimal]).generate
    rescue ConfigError => e
      print_config_error(e)
    rescue Errno::EACCES => e
      print_file_error("Permission denied", e.message)
    rescue Errno::ENOSPC
      print_file_error("Disk full", "No space left on device")
    rescue SystemCallError => e
      print_file_error("File operation failed", e.message)
    end

    private

    def apply_global_options
      UI.enabled = false if options[:no_color]
    end

    def print_config_error(error)
      puts
      puts "  #{UI.bold('Docyard')} v#{VERSION}"
      puts
      puts "  #{UI.red(error.message)}"
      puts
      exit(1)
    end

    def print_file_error(title, message)
      puts
      puts "  #{UI.bold('Docyard')} v#{VERSION}"
      puts
      puts "  #{UI.red("#{title}:")}"
      puts "    #{message}"
      puts
      exit(1)
    end
  end
end
