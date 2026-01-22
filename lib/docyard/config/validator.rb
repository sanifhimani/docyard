# frozen_string_literal: true

require_relative "validation_helpers"
require_relative "schema"
require_relative "key_validator"
require_relative "validators/section"
require_relative "validators/navigation"

module Docyard
  class Config
    class Validator
      include ValidationHelpers
      include Validators::Section
      include Validators::Navigation

      def initialize(config_data)
        @config = config_data
        @errors = []
        @key_errors = []
      end

      def validate!
        validate_unknown_keys
        validate_top_level
        validate_branding_section
        validate_socials_section
        validate_tabs_section
        validate_sidebar_setting
        validate_build_section
        validate_search_section
        validate_navigation_section
        validate_announcement_section
        validate_feedback_section

        raise_key_errors if @key_errors.any?
        raise ConfigError, format_errors if @errors.any?
      end

      private

      def validate_unknown_keys
        validate_top_level_keys
        validate_section_keys
        validate_array_item_keys
      end

      def validate_top_level_keys
        @key_errors.concat(KeyValidator.validate(@config, Schema::TOP_LEVEL, context: "docyard.yml"))
      end

      def validate_section_keys
        Schema::SECTIONS.each do |section, valid_keys|
          next unless @config[section].is_a?(Hash)

          @key_errors.concat(KeyValidator.validate(@config[section], valid_keys, context: section))
        end
      end

      def validate_array_item_keys
        validate_tabs_keys
        validate_cta_keys
        validate_announcement_button_keys
      end

      def validate_tabs_keys
        tabs = @config["tabs"]
        return unless tabs.is_a?(Array)

        tabs.each_with_index do |tab, idx|
          @key_errors.concat(KeyValidator.validate(tab, Schema::TAB, context: "tabs[#{idx}]"))
        end
      end

      def validate_cta_keys
        cta = @config.dig("navigation", "cta")
        return unless cta.is_a?(Array)

        cta.each_with_index do |item, idx|
          @key_errors.concat(KeyValidator.validate(item, Schema::CTA, context: "navigation.cta[#{idx}]"))
        end
      end

      def validate_announcement_button_keys
        button = @config.dig("announcement", "button")
        return unless button.is_a?(Hash)

        @key_errors.concat(KeyValidator.validate(button, Schema::ANNOUNCEMENT_BUTTON, context: "announcement.button"))
      end

      def raise_key_errors
        messages = @key_errors.map { |e| "#{e[:context]}: #{e[:message]}" }
        raise ConfigError, "Error in docyard.yml:\n#{messages.join("\n")}"
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
