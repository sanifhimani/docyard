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
  end
end
