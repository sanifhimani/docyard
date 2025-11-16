# frozen_string_literal: true

require "fileutils"

module Docyard
  class Initializer
    DOCS_DIR = "docs"
    TEMPLATE_DIR = File.join(__dir__, "templates", "markdown")
    CONFIG_TEMPLATE_DIR = File.join(__dir__, "templates", "config")

    TEMPLATES = {
      "index.md" => "index.md.erb",
      "getting-started/installation.md" => "getting-started/installation.md.erb",
      "guides/markdown-features.md" => "guides/markdown-features.md.erb",
      "guides/configuration.md" => "guides/configuration.md.erb"
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

      create_example_config
    end

    def copy_template(template_name, output_name)
      template_path = File.join(TEMPLATE_DIR, template_name)
      output_path = File.join(@docs_path, output_name)

      output_dir = File.dirname(output_path)
      FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)

      content = File.read(template_path)
      File.write(output_path, content)
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
      puts "┌─────────────────────────────────────────────────────────────┐"
      puts "│  ✓ Docyard initialized successfully                        │"
      puts "└─────────────────────────────────────────────────────────────┘"
      puts ""
    end

    def print_created_files
      puts "Created files:"
      puts ""
      print_file_tree
      puts ""
    end

    def print_next_steps
      puts "Next steps:"
      puts ""
      puts "  Start development server:"
      puts "    docyard serve"
      puts "    → http://localhost:4200"
      puts ""
      puts "  Build for production:"
      puts "    docyard build"
      puts ""
      puts "  Preview production build:"
      puts "    docyard preview"
      puts ""
    end

    def print_file_tree
      puts "  ├── docs/"

      grouped_files = TEMPLATES.keys.group_by { |file| File.dirname(file) }
      sorted_dirs = grouped_files.keys.sort

      sorted_dirs.each_with_index do |dir, dir_idx|
        print_directory_group(dir, grouped_files[dir], dir_idx == sorted_dirs.length - 1)
      end

      puts "  └── docyard.yml"
    end

    def print_directory_group(dir, files, is_last_dir)
      sorted_files = files.sort

      if dir == "."
        print_root_files(sorted_files, is_last_dir)
      else
        print_subdirectory(dir, sorted_files, is_last_dir)
      end
    end

    def print_root_files(files, is_last_dir)
      files.each_with_index do |file, idx|
        is_last = idx == files.length - 1 && is_last_dir
        prefix = is_last ? "  │   └──" : "  │   ├──"
        puts "#{prefix} #{file}"
      end
    end

    def print_subdirectory(dir, files, is_last_dir)
      dir_prefix = is_last_dir ? "  │   └──" : "  │   ├──"
      puts "#{dir_prefix} #{dir}/"

      files.each_with_index do |file, idx|
        print_subdirectory_file(file, idx, files.length, is_last_dir)
      end
    end

    def print_subdirectory_file(file, idx, total, is_last_dir)
      is_last_file = idx == total - 1
      file_prefix = is_last_dir ? "  │       " : "  │   │   "
      file_prefix += is_last_file ? "└──" : "├──"
      basename = File.basename(file)
      puts "#{file_prefix} #{basename}"
    end
  end
end
