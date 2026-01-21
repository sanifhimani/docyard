# frozen_string_literal: true

require "fileutils"

module Docyard
  class Initializer
    DOCS_DIR = "docs"
    TEMPLATES_DIR = File.join(__dir__, "templates", "init")

    attr_reader :project_name, :project_path, :docs_path, :force

    def initialize(project_name = nil, force: false)
      @project_name = project_name
      @project_path = project_name ? File.join(".", project_name) : "."
      @docs_path = File.join(@project_path, DOCS_DIR)
      @force = force
    end

    def run # rubocop:disable Naming/PredicateMethod
      return false unless check_existing_files

      create_project_directory if project_name
      create_structure
      print_success
      true
    end

    private

    def check_existing_files # rubocop:disable Naming/PredicateMethod
      return true if force
      return true unless files_exist?

      print_existing_files_warning
      return true if user_confirms_overwrite?

      print_abort_message
      false
    end

    def files_exist?
      File.exist?(docs_path) || File.exist?(config_path)
    end

    def config_path
      File.join(project_path, "docyard.yml")
    end

    def user_confirms_overwrite?
      print "\nOverwrite existing files? [y/N] "
      response = $stdin.gets&.strip&.downcase
      %w[y yes].include?(response)
    end

    def print_existing_files_warning
      puts ""
      puts "\e[33mWarning:\e[0m Existing files found:"
      puts "  - #{docs_path}/" if File.exist?(docs_path)
      puts "  - #{config_path}" if File.exist?(config_path)
    end

    def print_abort_message
      puts ""
      puts "Aborted. Use \e[1m--force\e[0m to overwrite existing files."
    end

    def create_project_directory
      FileUtils.mkdir_p(project_path)
    end

    def create_structure
      FileUtils.mkdir_p(docs_path)
      FileUtils.mkdir_p(File.join(docs_path, "public"))
      create_config_file
      create_sidebar_file
      create_starter_pages
    end

    def create_config_file
      template = File.read(File.join(TEMPLATES_DIR, "docyard.yml"))
      content = template.gsub("{{PROJECT_NAME}}", display_name)
      File.write(config_path, content)
    end

    def create_sidebar_file
      template = File.read(File.join(TEMPLATES_DIR, "_sidebar.yml"))
      File.write(File.join(docs_path, "_sidebar.yml"), template)
    end

    def create_starter_pages
      pages_dir = File.join(TEMPLATES_DIR, "pages")
      Dir.glob(File.join(pages_dir, "*.md")).each do |template_path|
        filename = File.basename(template_path)
        content = File.read(template_path).gsub("{{PROJECT_NAME}}", display_name)
        File.write(File.join(docs_path, filename), content)
      end
    end

    def display_name
      return "My Documentation" unless project_name

      project_name.split(/[-_]/).map(&:capitalize).join(" ")
    end

    def print_success
      puts ""
      puts "\e[32m#{success_icon} Docyard project initialized successfully!\e[0m"
      puts ""
      print_created_structure
      print_next_steps
    end

    def success_icon
      "\u2714"
    end

    def print_created_structure
      puts "Created:"
      puts ""
      if project_name
        puts "  \e[1m#{project_name}/\e[0m"
        puts "  \u251C\u2500\u2500 docyard.yml"
        puts "  \u2514\u2500\u2500 docs/"
      else
        puts "  \e[1mdocyard.yml\e[0m"
        puts "  \e[1mdocs/\e[0m"
      end
      puts "      \u251C\u2500\u2500 _sidebar.yml"
      puts "      \u251C\u2500\u2500 index.md"
      puts "      \u251C\u2500\u2500 getting-started.md"
      puts "      \u251C\u2500\u2500 components.md"
      puts "      \u2514\u2500\u2500 public/"
      puts ""
    end

    def print_next_steps
      puts "Next steps:"
      puts ""
      if project_name
        puts "  \e[1mcd #{project_name}\e[0m"
        puts ""
      end
      puts "  Start the development server:"
      puts "  \e[1m$ docyard serve\e[0m"
      puts ""
      puts "  Then open \e[4mhttp://localhost:4200\e[0m in your browser"
      puts ""
    end
  end
end
