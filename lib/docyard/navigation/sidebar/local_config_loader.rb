# frozen_string_literal: true

require "yaml"

module Docyard
  module Sidebar
    class LocalConfigLoader
      SIDEBAR_CONFIG_FILE = "_sidebar.yml"

      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
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
        normalize_config(content)
      rescue Psych::SyntaxError => e
        warn "Warning: Invalid YAML in #{config_file_path}: #{e.message}"
        nil
      rescue StandardError => e
        warn "Warning: Error reading #{config_file_path}: #{e.message}"
        nil
      end

      def normalize_config(content)
        return nil if content.nil?
        return content if content.is_a?(Array)

        content["items"] if content.is_a?(Hash)
      end
    end
  end
end
