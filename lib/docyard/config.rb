# frozen_string_literal: true

require "yaml"
require_relative "config/validator"
require_relative "config/constants"

module Docyard
  class Config
    DEFAULT_CONFIG = {
      "title" => Constants::DEFAULT_SITE_TITLE,
      "description" => "",
      "branding" => {
        "logo" => nil,
        "favicon" => nil,
        "credits" => true,
        "copyright" => nil
      },
      "socials" => {},
      "tabs" => [],
      "build" => {
        "output" => "dist",
        "base" => "/"
      },
      "search" => {
        "enabled" => true,
        "placeholder" => "Search...",
        "exclude" => []
      },
      "navigation" => {
        "cta" => [],
        "breadcrumbs" => true
      },
      "announcement" => nil
    }.freeze

    attr_reader :data, :file_path

    def self.load(project_root = Dir.pwd)
      new(project_root)
    end

    def initialize(project_root = Dir.pwd)
      @project_root = project_root
      @file_path = File.join(project_root, "docyard.yml")
      @data = load_config_data
      validate!
    end

    def file_exists?
      File.exist?(file_path)
    end

    def title
      data["title"]
    end

    def description
      data["description"]
    end

    def branding
      @branding ||= ConfigSection.new(data["branding"])
    end

    def socials
      data["socials"]
    end

    def tabs
      data["tabs"]
    end

    def build
      @build ||= ConfigSection.new(data["build"])
    end

    def search
      @search ||= ConfigSection.new(data["search"])
    end

    def navigation
      @navigation ||= ConfigSection.new(data["navigation"])
    end

    def announcement
      @announcement ||= data["announcement"] ? ConfigSection.new(data["announcement"]) : nil
    end

    private

    def load_config_data
      if file_exists?
        load_and_merge_config
      else
        deep_dup(DEFAULT_CONFIG)
      end
    end

    def load_and_merge_config
      yaml_content = YAML.load_file(file_path)
      deep_merge(deep_dup(DEFAULT_CONFIG), yaml_content || {})
    rescue Psych::SyntaxError => e
      raise ConfigError, build_yaml_error_message(e)
    rescue StandardError => e
      raise ConfigError, "Error loading docyard.yml: #{e.message}"
    end

    def deep_merge(hash1, hash2)
      hash1.merge(hash2) do |_key, v1, v2|
        if v2.nil?
          v1
        elsif v1.is_a?(Hash) && v2.is_a?(Hash)
          deep_merge(v1, v2)
        else
          v2
        end
      end
    end

    def deep_dup(hash)
      hash.transform_values do |value|
        case value
        when Hash then deep_dup(value)
        when Array then value.map { |v| v.is_a?(Hash) ? deep_dup(v) : v }
        else value
        end
      end
    end

    def build_yaml_error_message(error)
      message = "Invalid YAML in docyard.yml:\n\n"
      message += "  #{error.message}\n\n"
      message += "Fix: Check YAML syntax"
      message += " at line #{error.line}" if error.respond_to?(:line)
      message
    end

    def validate!
      Validator.new(data).validate!
    end
  end

  class ConfigSection
    def initialize(data)
      @data = data || {}
    end

    def method_missing(method, *args)
      return @data[method.to_s] if args.empty?

      super
    end

    def respond_to_missing?(method, include_private = false)
      @data.key?(method.to_s) || super
    end
  end

  class ConfigError < StandardError; end
end
