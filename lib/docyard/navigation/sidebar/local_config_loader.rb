# frozen_string_literal: true

require "yaml"

module Docyard
  module Sidebar
    class LocalConfigLoader
      SIDEBAR_CONFIG_FILE = "_sidebar.yml"

      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
        @key_errors = []
      end

      def load
        return nil unless config_file_exists?

        parse_config_file
      end

      def config_file_exists?
        File.file?(config_file_path)
      end

      private

      def config_file_path
        File.join(docs_path, SIDEBAR_CONFIG_FILE)
      end

      def parse_config_file
        content = YAML.load_file(config_file_path)
        items = normalize_config(content)
        validate_items(items) if items
        report_key_errors
        items
      rescue Psych::SyntaxError => e
        Docyard.logger.warn("Invalid YAML in #{config_file_path}: #{e.message}")
        nil
      rescue ConfigError
        raise
      rescue StandardError => e
        Docyard.logger.warn("Error reading #{config_file_path}: #{e.message}")
        nil
      end

      def normalize_config(content)
        return nil if content.nil?
        return content if content.is_a?(Array)

        content["items"] if content.is_a?(Hash)
      end

      def validate_items(items, path_prefix: "")
        return unless items.is_a?(Array)

        items.each_with_index do |item, idx|
          validate_item(item, "#{path_prefix}[#{idx}]")
        end
      end

      def validate_item(item, context)
        return unless item.is_a?(Hash)

        if external_link?(item)
          validate_external_link(item, context)
        else
          validate_sidebar_item(item, context)
        end
      end

      def external_link?(item)
        item.key?("link") || item.key?(:link)
      end

      def validate_external_link(item, context)
        errors = Config::KeyValidator.validate(item, Config::Schema::SIDEBAR_EXTERNAL_LINK, context: context)
        @key_errors.concat(errors)
      end

      def validate_sidebar_item(item, context)
        slug, options = extract_slug_and_options(item)
        return unless options.is_a?(Hash)

        errors = Config::KeyValidator.validate(options, Config::Schema::SIDEBAR_ITEM, context: context)
        @key_errors.concat(errors)
        validate_nested_items(options, slug, context)
      end

      def extract_slug_and_options(item)
        first_key = item.keys.first
        if first_key.is_a?(String) && !external_link?(item)
          [first_key, item[first_key]]
        else
          [nil, item]
        end
      end

      def validate_nested_items(options, slug, context)
        nested = options["items"] || options[:items]
        return unless nested

        nested_context = slug ? "#{context}.#{slug}" : context
        validate_items(nested, path_prefix: nested_context)
      end

      def report_key_errors
        return if @key_errors.empty?

        messages = @key_errors.map { |e| "#{e[:context]}: #{e[:message]}" }
        raise ConfigError, "Error in #{config_file_path}:\n#{messages.join("\n")}"
      end
    end
  end
end
