# frozen_string_literal: true

module Docyard
  class Config
    module ValidationHelpers
      private

      def validate_string(value, field_name)
        return if value.nil? || value.is_a?(String)

        add_error(field: field_name, error: "must be a string", got: value.class.name, fix: "Change to a string value")
      end

      def validate_boolean(value, field_name)
        return if [true, false].include?(value)

        add_error(field: field_name, error: "must be true or false", got: value.inspect, fix: "Change to true or false")
      end

      def validate_url(value, field_name)
        return if value.nil? || value.is_a?(String)

        add_error(field: field_name, error: "must be a URL string", got: value.class.name,
                  fix: "Change to a URL string")
      end

      def validate_array(value, field_name)
        return if value.nil? || value.is_a?(Array)

        add_array_error(field_name)
      end

      def validate_file_path_or_url(value, field_name)
        return if value.nil?
        return add_type_error(field_name, "file path or URL (string)", value.class.name) unless value.is_a?(String)
        return if url?(value)

        file_path = File.absolute_path?(value) ? value : File.join("docs/public", value)
        return if File.exist?(file_path)

        add_error(field: field_name, error: "file not found", got: value,
                  fix: "Place the file in docs/public/ directory (e.g., 'logo.svg' for docs/public/logo.svg)")
      end

      def validate_no_slashes(value, field_name)
        return if value.nil? || !value.is_a?(String)
        return unless value.include?("/") || value.include?("\\")

        add_error(field: field_name, error: "cannot contain slashes", got: value,
                  fix: "Use a simple directory name like 'dist' or '_site'")
      end

      def validate_starts_with_slash(value, field_name)
        return if value.nil? || value.start_with?("/")

        add_error(field: field_name, error: "must start with /", got: value, fix: "Change to '/#{value}'")
      end

      def url?(value)
        value.match?(%r{\Ahttps?://})
      end

      def add_error(error_data)
        @errors << error_data
      end

      def add_type_error(field, expected, got)
        add_error(field: field, error: "must be a #{expected}", got: got, fix: "Change to a #{expected}")
      end

      def add_hash_error(field)
        add_error(field: field, error: "must be a hash", got: @config[field].class.name,
                  fix: "Change to a hash with platform names as keys and URLs as values")
      end

      def add_array_error(field)
        value = field.split(".").reduce(@config) { |h, k| h&.[](k) }
        add_error(field: field, error: "must be an array", got: value.class.name, fix: "Change to an array")
      end
    end
  end
end
