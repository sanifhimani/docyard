# frozen_string_literal: true

require "yaml"

module Docyard
  module Sidebar
    class LocalConfigLoader
      SIDEBAR_CONFIG_FILE = "_sidebar.yml"

      attr_reader :docs_path, :key_errors

      def initialize(docs_path, validate: true)
        @docs_path = docs_path
        @validate = validate
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

        items.each do |item|
          validate_item(item, path_prefix)
        end
      end

      def validate_item(item, path_prefix)
        return unless item.is_a?(Hash)

        if external_link?(item)
          validate_external_link(item, path_prefix)
        else
          validate_sidebar_item(item, path_prefix)
        end
      end

      def external_link?(item)
        item.key?("link") || item.key?(:link)
      end

      def validate_external_link(item, path_prefix)
        link_text = item["text"] || item[:text] || item["link"] || item[:link]
        context = build_context(path_prefix, link_text)
        errors = Config::Schema.validate_keys(item, Config::Schema::SIDEBAR_EXTERNAL_LINK_KEYS, context: context)
        @key_errors.concat(errors)
      end

      def validate_sidebar_item(item, path_prefix)
        slug, options = extract_slug_and_options(item)
        return unless options.is_a?(Hash)

        context = build_context(path_prefix, slug)
        errors = Config::Schema.validate_keys(options, Config::Schema::SIDEBAR_ITEM_KEYS, context: context)
        @key_errors.concat(errors)
        validate_nested_items(options, context)
      end

      def extract_slug_and_options(item)
        first_key = item.keys.first
        if first_key.is_a?(String) && !external_link?(item)
          [first_key, item[first_key]]
        else
          [nil, item]
        end
      end

      def build_context(prefix, name)
        return name.to_s if prefix.empty?

        "#{prefix}.#{name}"
      end

      def validate_nested_items(options, context)
        nested = options["items"] || options[:items]
        return unless nested

        validate_items(nested, path_prefix: context)
      end

      def report_key_errors
        return if @key_errors.empty?
        return unless @validate

        messages = @key_errors.map { |e| "#{e[:context]}: #{e[:message]}" }
        raise ConfigError, "Error in #{config_file_path}:\n#{messages.join("\n")}"
      end
    end
  end
end
