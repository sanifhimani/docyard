# frozen_string_literal: true

module Docyard
  class Customizer
    CUSTOM_DIR = "_custom"
    STYLES_FILE = "styles.css"
    SCRIPTS_FILE = "scripts.js"
    VARIABLES_PATH = File.join(__dir__, "templates", "assets", "css", "variables.css")

    CATEGORY_PATTERNS = {
      /^--sidebar-width/ => "Layout",
      /^--sidebar/ => "Sidebar",
      /^--code|^--diff/ => "Code",
      /^--callout/ => "Callouts",
      /^--table|^--hr/ => "Tables",
      /^--search|^--overlay/ => "Search",
      /^--font|^--text|^--leading/ => "Typography",
      /^--spacing/ => "Spacing",
      /^--toc|^--header|^--content|^--layout|^--tab-bar|^--secondary-header/ => "Layout",
      /^--radius/ => "Radius",
      /^--shadow/ => "Shadows",
      /^--transition/ => "Transitions",
      /^--z-/ => "Z-Index",
      /^--ring/ => "Other"
    }.freeze

    CATEGORIES = %w[
      Colors Sidebar Code Callouts Tables Search
      Typography Spacing Layout Radius Shadows Transitions Z-Index Other
    ].freeze

    attr_reader :config, :minimal

    def initialize(minimal: false)
      @config = Config.load
      @minimal = minimal
    end

    def generate
      validate_source_directory
      create_custom_directory
      write_styles_file
      write_scripts_file
      print_success
    end

    private

    def validate_source_directory
      return if File.directory?(config.source)

      raise ConfigError, "Source directory '#{config.source}' does not exist"
    end

    def custom_dir_path
      @custom_dir_path ||= File.join(config.source, CUSTOM_DIR)
    end

    def styles_path
      @styles_path ||= File.join(custom_dir_path, STYLES_FILE)
    end

    def scripts_path
      @scripts_path ||= File.join(custom_dir_path, SCRIPTS_FILE)
    end

    def create_custom_directory
      FileUtils.mkdir_p(custom_dir_path)
    end

    def write_styles_file
      File.write(styles_path, minimal ? minimal_styles : annotated_styles)
    end

    def write_scripts_file
      File.write(scripts_path, minimal ? minimal_scripts : annotated_scripts)
    end

    def annotated_styles
      build_annotated_css(parse_variables)
    end

    def minimal_styles
      build_minimal_css(parse_variables)
    end

    def parse_variables
      content = File.read(VARIABLES_PATH)
      { light: extract_variables(content, ":root"), dark: extract_variables(content, ".dark") }
    end

    def extract_variables(content, selector)
      match = content.match(/#{Regexp.escape(selector)}\s*\{([^}]+)\}/m)
      return [] unless match

      match[1].scan(/(--[\w-]+):\s*([^;]+);/).map { |name, value| { name: name, value: value.strip } }
    end

    def build_annotated_css(variables)
      light = format_annotated(variables[:light])
      dark = format_annotated(variables[:dark])
      "#{css_header}:root {\n#{light}\n}\n\n.dark {\n#{dark}\n}\n"
    end

    def build_minimal_css(variables)
      ":root {\n#{format_minimal(variables[:light])}\n}\n\n.dark {\n#{format_minimal(variables[:dark])}\n}\n"
    end

    def css_header
      <<~HEADER
        /* =============================================================================
           DOCYARD THEME CUSTOMIZATION

           Uncomment and modify variables to customize your site.
           Delete any variables you don't need to change.

           Generated with: docyard customize
           ============================================================================= */

      HEADER
    end

    def format_annotated(vars)
      group_variables(vars).flat_map do |category, category_vars|
        ["  /* #{category} */"] + category_vars.map { |v| "  /* #{v[:name]}: #{v[:value]}; */" } + [""]
      end.join("\n").rstrip
    end

    def format_minimal(vars)
      vars.map { |var| "  /* #{var[:name]}: #{var[:value]}; */" }.join("\n")
    end

    def group_variables(vars)
      groups = CATEGORIES.to_h { |cat| [cat, []] }
      vars.each { |var| groups[categorize_variable(var[:name])] << var }
      groups.reject { |_, v| v.empty? }
    end

    def categorize_variable(name)
      CATEGORY_PATTERNS.each { |pattern, category| return category if name.match?(pattern) }
      "Colors"
    end

    def annotated_scripts
      "#{js_header}document.addEventListener('DOMContentLoaded', function() {\n  // Your custom JavaScript here\n});\n"
    end

    def js_header
      <<~HEADER
        /* =============================================================================
           DOCYARD CUSTOM SCRIPTS

           This file is loaded on every page after the default scripts.

           Generated with: docyard customize
           ============================================================================= */

      HEADER
    end

    def minimal_scripts
      "document.addEventListener('DOMContentLoaded', function() {\n  // Your custom JavaScript here\n});\n"
    end

    def print_success
      puts
      print_header
      print_created_files
      print_next_steps
    end

    def print_header
      puts "  #{UI.bold('Docyard')} v#{VERSION}"
      puts
    end

    def print_created_files
      puts "  #{UI.success('Created:')}"
      puts UI.dim("    #{relative_path(custom_dir_path)}/")
      puts UI.dim("        #{STYLES_FILE}")
      puts UI.dim("        #{SCRIPTS_FILE}")
      puts
    end

    def print_next_steps
      puts "  #{UI.bold('Next steps:')}"
      puts "    Edit #{UI.cyan(relative_path(styles_path))} to customize theme"
      puts "    Changes apply on next serve or build"
      puts
    end

    def relative_path(path)
      path.sub("#{Dir.pwd}/", "")
    end
  end
end
