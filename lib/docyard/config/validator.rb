# frozen_string_literal: true

require_relative "validation_helpers"

module Docyard
  class Config
    class Validator
      include ValidationHelpers

      def initialize(config_data)
        @config = config_data
        @errors = []
      end

      def validate!
        validate_top_level
        validate_branding_section
        validate_socials_section
        validate_tabs_section
        validate_sidebar_setting
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

      def validate_sidebar_setting
        sidebar = @config["sidebar"]
        return if sidebar.nil? || Config::SIDEBAR_MODES.include?(sidebar)

        add_error(
          field: "sidebar",
          error: "must be one of: #{Config::SIDEBAR_MODES.join(', ')}",
          got: sidebar.inspect,
          fix: "Change to 'config', 'auto', or 'distributed'"
        )
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

      def format_errors
        errors_text = @errors.map do |err|
          "   Field: #{err[:field]}\n   Error: #{err[:error]}\n   Got: #{err[:got]}\n   Fix: #{err[:fix]}"
        end.join("\n\n")
        "Error in docyard.yml:\n\n#{errors_text}"
      end
    end
  end
end
