# frozen_string_literal: true

module Docyard
  class Config
    class Validator
      def initialize(config_data)
        @config = config_data
        @errors = []
      end

      def validate!
        validate_site_section
        validate_build_section

        raise ConfigError, format_errors if @errors.any?
      end

      private

      def validate_site_section
        site = @config["site"]

        validate_string(site["title"], "site.title")
        validate_string(site["description"], "site.description")
        validate_file_path(site["logo"], "site.logo")
        validate_file_path(site["logo_dark"], "site.logo_dark")
        validate_file_path(site["favicon"], "site.favicon")
      end

      def validate_build_section
        build = @config["build"]

        validate_string(build["output_dir"], "build.output_dir")
        validate_no_slashes(build["output_dir"], "build.output_dir")
        validate_string(build["base_url"], "build.base_url")
        validate_starts_with_slash(build["base_url"], "build.base_url")
        validate_boolean(build["clean"], "build.clean")
      end

      def validate_string(value, field_name)
        return if value.nil?
        return if value.is_a?(String)

        add_error(
          field: field_name,
          error: "must be a string",
          got: value.class.name,
          fix: "Change to a string value"
        )
      end

      def validate_boolean(value, field_name)
        return if [true, false].include?(value)

        add_error(
          field: field_name,
          error: "must be true or false",
          got: value.inspect,
          fix: "Change to true or false"
        )
      end

      def validate_file_path(value, field_name)
        return if value.nil?
        return add_file_path_type_error(value, field_name) unless value.is_a?(String)
        return if File.exist?(value)

        add_file_not_found_error(value, field_name)
      end

      def add_file_path_type_error(value, field_name)
        add_error(
          field: field_name,
          error: "must be a file path (string)",
          got: value.class.name,
          fix: "Change to a string file path"
        )
      end

      def add_file_not_found_error(value, field_name)
        add_error(
          field: field_name,
          error: "file not found",
          got: value,
          fix: "Create the file or update the path"
        )
      end

      def validate_no_slashes(value, field_name)
        return if value.nil?
        return unless value.is_a?(String)
        return unless value.include?("/") || value.include?("\\")

        add_error(
          field: field_name,
          error: "cannot contain slashes",
          got: value,
          fix: "Use a simple directory name like 'dist' or '_site'"
        )
      end

      def validate_starts_with_slash(value, field_name)
        return if value.nil?
        return if value.start_with?("/")

        add_error(
          field: field_name,
          error: "must start with /",
          got: value,
          fix: "Change to '/#{value}'"
        )
      end

      def add_error(error_data)
        @errors << error_data
      end

      def format_errors
        message = "Error in docyard.yml:\n\n"

        @errors.each do |err|
          message += "   Field: #{err[:field]}\n"
          message += "   Error: #{err[:error]}\n"
          message += "   Got: #{err[:got]}\n"
          message += "   Fix: #{err[:fix]}\n\n"
        end

        message.chomp
      end
    end
  end
end
