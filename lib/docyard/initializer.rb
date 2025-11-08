# frozen_string_literal: true

require "fileutils"

module Docyard
  class Initializer
    DOCS_DIR = "docs"
    TEMPLATE_DIR = File.join(__dir__, "templates", "markdown")

    TEMPLATES = {
      "index.md" => "index.md.erb",
      "getting-started.md" => "getting-started.md.erb"
    }.freeze

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

      TEMPLATES.each do |output_name, template_name|
        copy_template(template_name, output_name)
      end
    end

    def copy_template(template_name, output_name)
      template_path = File.join(TEMPLATE_DIR, template_name)
      output_path = File.join(@docs_path, output_name)

      content = File.read(template_path)
      File.write(output_path, content)
    end

    def print_already_exists_error
      puts "Error: #{DOCS_DIR}/ folder already exists"
      puts "   Remove it first or run docyard in a different directory"
    end

    def print_success
      puts "Docyard initialized successfully!"
      puts ""
      puts "Created:"
      TEMPLATES.each_key { |file| puts "  #{DOCS_DIR}/#{file}" }
      puts ""
      puts "Next steps:"
      puts "  1. Edit your markdown files in #{DOCS_DIR}/"
      puts "  2. Run 'docyard serve' to preview your documentation locally"
    end
  end
end
