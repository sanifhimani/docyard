# frozen_string_literal: true

module Docyard
  class Error < StandardError; end

  class ConfigError < Error; end

  class SidebarConfigError < Error; end

  class FileNotFoundError < Error
    attr_reader :path

    def initialize(path)
      @path = path
      super("File not found: #{path}")
    end
  end

  class InvalidPathError < Error; end

  class MarkdownParseError < Error
    attr_reader :file_path, :original_error

    def initialize(file_path, original_error)
      @file_path = file_path
      @original_error = original_error
      super("Failed to parse markdown file #{file_path}: #{original_error.message}")
    end
  end

  class TemplateRenderError < Error
    attr_reader :template_path, :original_error

    def initialize(template_path, original_error)
      @template_path = template_path
      @original_error = original_error
      super("Failed to render template #{template_path}: #{original_error.message}")
    end
  end

  class ReloadCheckError < Error
    attr_reader :original_error

    def initialize(original_error)
      @original_error = original_error
      super("Reload check failed: #{original_error.message}")
    end
  end

  class AssetNotFoundError < Error
    attr_reader :asset_path

    def initialize(asset_path)
      @asset_path = asset_path
      super("Asset not found: #{asset_path}")
    end
  end

  class BuildError < Error; end
end
