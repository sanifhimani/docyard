# frozen_string_literal: true

require "yaml"
require_relative "config/section"
require_relative "config/validator"
require_relative "constants"
require_relative "utils/hash_utils"

module Docyard
  class Config
    DEFAULT_CONFIG = {
      "title" => Constants::DEFAULT_SITE_TITLE,
      "description" => "",
      "url" => nil,
      "og_image" => nil,
      "twitter" => nil,
      "source" => "docs",
      "branding" => { "logo" => nil, "favicon" => nil, "credits" => true, "copyright" => nil, "color" => nil },
      "socials" => {},
      "tabs" => [],
      "sidebar" => "config",
      "build" => { "output" => "dist", "base" => "/", "strict" => false },
      "search" => { "enabled" => true, "placeholder" => "Search...", "exclude" => [] },
      "navigation" => { "cta" => [], "breadcrumbs" => true },
      "announcement" => nil,
      "repo" => { "url" => nil, "branch" => "main", "edit_path" => nil, "edit_link" => true,
                  "last_updated" => true },
      "analytics" => { "google" => nil, "plausible" => nil, "fathom" => nil, "script" => nil },
      "feedback" => { "enabled" => false, "question" => "Was this page helpful?" }
    }.freeze

    attr_reader :data, :file_path

    def self.load(project_root = Dir.pwd)
      new(project_root)
    end

    def initialize(project_root = Dir.pwd)
      @project_root = project_root
      @file_path = File.join(project_root, "docyard.yml")
      @data = load_config_data
    end

    def file_exists?
      File.exist?(file_path)
    end

    def title = data["title"]
    def description = data["description"]
    def url = data["url"]
    def og_image = data["og_image"]
    def twitter = data["twitter"]
    def source = data["source"]
    def public_dir = File.join(source, "public")
    def socials = data["socials"]
    def tabs = data["tabs"]
    def sidebar = data["sidebar"]

    def branding = @branding ||= Section.new(data["branding"])
    def build = @build ||= Section.new(data["build"])
    def search = @search ||= Section.new(data["search"])
    def navigation = @navigation ||= Section.new(data["navigation"])
    def repo = @repo ||= Section.new(data["repo"])
    def analytics = @analytics ||= Section.new(data["analytics"])
    def feedback = @feedback ||= Section.new(data["feedback"])

    def announcement
      @announcement ||= data["announcement"] ? Section.new(data["announcement"]) : nil
    end

    private

    def load_config_data
      file_exists? ? load_and_merge_config : Utils::HashUtils.deep_dup(DEFAULT_CONFIG)
    end

    def load_and_merge_config
      yaml_content = YAML.load_file(file_path)
      Utils::HashUtils.deep_merge(Utils::HashUtils.deep_dup(DEFAULT_CONFIG), yaml_content || {})
    rescue Psych::SyntaxError => e
      raise ConfigError, build_yaml_error_message(e)
    rescue StandardError => e
      raise ConfigError, "Error loading docyard.yml: #{e.message}"
    end

    def build_yaml_error_message(error)
      message = "Invalid YAML in docyard.yml:\n\n  #{error.message}\n\nFix: Check YAML syntax"
      message += " at line #{error.line}" if error.respond_to?(:line)
      message
    end
  end
end
