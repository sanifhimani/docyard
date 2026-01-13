# frozen_string_literal: true

module Docyard
  class Config
    class Validator
      def initialize(config_data)
        @config = config_data
        @errors = []
      end

      def validate!
        validate_top_level
        validate_branding_section
        validate_socials_section
        validate_tabs_section
        validate_build_section
        validate_search_section
        validate_navigation_section

        raise ConfigError, format_errors if @errors.any?
      end

      private

      def validate_top_level
        validate_string(@config["title"], "title")
        validate_string(@config["description"], "description")
      end

      def validate_branding_section
        branding = @config["branding"]
        return unless branding

        validate_file_path_or_url(branding["logo"], "branding.logo")
        validate_file_path_or_url(branding["favicon"], "branding.favicon")
        validate_boolean(branding["credits"], "branding.credits") if branding.key?("credits")
      end

      def validate_socials_section
        socials = @config["socials"]
        return unless socials
        return add_hash_error("socials") unless socials.is_a?(Hash)

        socials.each { |platform, url| validate_url(url, "socials.#{platform}") unless platform == "custom" }
        validate_custom_socials(socials["custom"]) if socials.key?("custom")
      end

      def validate_custom_socials(custom)
        return if custom.nil?
        return add_array_error("socials.custom") unless custom.is_a?(Array)

        custom.each_with_index do |item, index|
          validate_string(item["icon"], "socials.custom[#{index}].icon")
          validate_url(item["href"], "socials.custom[#{index}].href")
        end
      end

      def validate_tabs_section
        tabs = @config["tabs"]
        return unless tabs
        return add_array_error("tabs") unless tabs.is_a?(Array)

        tabs.each_with_index do |tab, index|
          validate_string(tab["text"], "tabs[#{index}].text")
          validate_string(tab["href"], "tabs[#{index}].href")
          validate_boolean(tab["external"], "tabs[#{index}].external") if tab.key?("external")
        end
      end

      def validate_build_section
        build = @config["build"]
        return unless build

        validate_string(build["output"], "build.output")
        validate_no_slashes(build["output"], "build.output")
        validate_string(build["base"], "build.base")
        validate_starts_with_slash(build["base"], "build.base")
      end

      def validate_search_section
        search = @config["search"]
        return unless search

        validate_boolean(search["enabled"], "search.enabled") if search.key?("enabled")
        validate_string(search["placeholder"], "search.placeholder") if search.key?("placeholder")
        validate_array(search["exclude"], "search.exclude") if search.key?("exclude")
      end

      def validate_navigation_section
        cta = @config.dig("navigation", "cta")
        return if cta.nil?
        return add_array_error("navigation.cta") unless cta.is_a?(Array)

        validate_cta_max_count(cta)
        validate_cta_items(cta)
      end

      def validate_cta_items(cta)
        cta.each_with_index do |item, idx|
          validate_string(item["text"], "navigation.cta[#{idx}].text")
          validate_string(item["href"], "navigation.cta[#{idx}].href")
          validate_cta_variant(item["variant"], idx) if item.key?("variant")
          validate_boolean(item["external"], "navigation.cta[#{idx}].external") if item.key?("external")
        end
      end

      def validate_cta_max_count(cta)
        return if cta.length <= 2

        add_error(field: "navigation.cta", error: "maximum 2 CTAs allowed",
                  got: "#{cta.length} items", fix: "Remove extra CTA items to have at most 2")
      end

      def validate_cta_variant(variant, idx)
        return if variant.nil? || %w[primary secondary].include?(variant)

        add_error(field: "navigation.cta[#{idx}].variant", error: "must be 'primary' or 'secondary'",
                  got: variant, fix: "Change to 'primary' or 'secondary'")
      end

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

        add_error(field: field_name, error: "must be a URL string",
                  got: value.class.name, fix: "Change to a URL string")
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

      def format_errors
        errors_text = @errors.map do |err|
          "   Field: #{err[:field]}\n   Error: #{err[:error]}\n   Got: #{err[:got]}\n   Fix: #{err[:fix]}"
        end.join("\n\n")
        "Error in docyard.yml:\n\n#{errors_text}"
      end
    end
  end
end
