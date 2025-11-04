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

    desc "init", "Initialize a new docyard project"
    def init
      initializer = Docyard::Initializer.new
      exit(1) unless initializer.run
    end

    desc "serve", "Start the development server"
    method_option :port, type: :numeric, default: 4200, aliases: "-p", desc: "Port to run the server on"
    method_option :host, type: :string, default: "localhost", aliases: "-h", desc: "Host to bind the server to"
    def serve
      require_relative "server"
      server = Docyard::Server.new(
        port: options[:port],
        host: options[:host]
      )
      server.start
    end
  end
end
