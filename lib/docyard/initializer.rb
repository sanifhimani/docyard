# frozen_string_literal: true

require "fileutils"

module Docyard
  class Initializer
    DOCS_DIR = "docs"
    CONFIG_TEMPLATE_DIR = File.join(__dir__, "templates", "config")

    def initialize(path = ".")
      @path = path
      @docs_path = File.join(@path, DOCS_DIR)
    end

    def run
      if already_initialized?
        print_already_exists_error
        return
      end

      create_structure
      print_success
      true
    end

    private

    def already_initialized?
      File.exist?(@docs_path)
    end

    def create_structure
      FileUtils.mkdir_p(@docs_path)
      create_index_file
      create_example_config
    end

    def create_index_file
      index_path = File.join(@docs_path, "index.md")
      content = <<~MARKDOWN
        ---
        title: Welcome
        ---

        # Welcome to Your Documentation

        Start writing your documentation here.
      MARKDOWN
      File.write(index_path, content)
    end

    def create_example_config
      config_path = File.join(@path, "docyard.yml")
      return if File.exist?(config_path)

      template_path = File.join(CONFIG_TEMPLATE_DIR, "docyard.yml.erb")
      config_content = File.read(template_path)

      File.write(config_path, config_content)
    end

    def print_already_exists_error
      puts "Error: #{DOCS_DIR}/ folder already exists"
      puts "   Remove it first or run docyard in a different directory"
    end

    def print_success
      print_banner
      print_created_files
      print_next_steps
    end

    def print_banner
      puts ""
      puts "Docyard initialized successfully"
      puts ""
    end

    def print_created_files
      puts "Created files:"
      puts ""
      puts "  docs/"
      puts "    index.md"
      puts "  docyard.yml"
      puts ""
    end

    def print_next_steps
      puts "Next steps:"
      puts ""
      puts "  Start development server:"
      puts "    docyard serve"
      puts ""
      puts "  Build for production:"
      puts "    docyard build"
      puts ""
    end
  end
end
