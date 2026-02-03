# frozen_string_literal: true

require "digest"
require_relative "../utils/path_utils"

module Docyard
  class AssetHandler
    TEMPLATES_ASSETS_PATH = File.join(__dir__, "../templates", "assets")
    CACHE_MAX_AGE = 3600
    DEFAULT_PUBLIC_DIR = "docs/public"
    DEFAULT_DOCS_PATH = "docs"

    attr_reader :public_dir, :docs_path

    CONTENT_TYPES = {
      ".css" => "text/css; charset=utf-8",
      ".js" => "application/javascript; charset=utf-8",
      ".png" => "image/png",
      ".jpg" => "image/jpeg",
      ".jpeg" => "image/jpeg",
      ".gif" => "image/gif",
      ".webp" => "image/webp",
      ".avif" => "image/avif",
      ".svg" => "image/svg+xml",
      ".woff" => "font/woff",
      ".woff2" => "font/woff2",
      ".ttf" => "font/ttf",
      ".ico" => "image/x-icon",
      ".pdf" => "application/pdf",
      ".mp4" => "video/mp4",
      ".webm" => "video/webm"
    }.freeze

    def initialize(public_dir: DEFAULT_PUBLIC_DIR, docs_path: DEFAULT_DOCS_PATH)
      @public_dir = public_dir
      @docs_path = docs_path
    end

    def serve_docyard_assets(request_path)
      asset_path = Utils::PathUtils.decode_path(request_path.delete_prefix("/_docyard/"))

      return serve_components_css if asset_path == "css/components.css"
      return serve_components_js if asset_path == "js/components.js"
      return serve_custom_css if asset_path == "css/custom.css"
      return serve_custom_js if asset_path == "js/custom.js"

      file_path = safe_asset_path(asset_path, TEMPLATES_ASSETS_PATH)
      return forbidden_response unless file_path
      return not_found_response unless File.file?(file_path)

      serve_file(file_path)
    end

    def serve_public_file(request_path)
      asset_path = Utils::PathUtils.decode_path(request_path.delete_prefix("/"))

      file_path = safe_asset_path(asset_path, public_dir)
      return nil unless file_path && File.file?(file_path)

      serve_file(file_path)
    end

    private

    def safe_asset_path(relative_path, base_dir)
      Utils::PathUtils.resolve_safe_path(relative_path, base_dir)
    end

    def serve_file(file_path)
      content = File.read(file_path)
      headers = build_cache_headers(content, File.mtime(file_path))
      headers["Content-Type"] = detect_content_type(file_path)

      [200, headers, [content]]
    end

    def serve_components_css
      content = concatenate_component_css
      headers = build_cache_headers(content)
      headers["Content-Type"] = "text/css; charset=utf-8"

      [200, headers, [content]]
    end

    def concatenate_component_css
      components_dir = File.join(TEMPLATES_ASSETS_PATH, "css", "components")
      return "" unless Dir.exist?(components_dir)

      css_files = Dir.glob(File.join(components_dir, "*.css"))
      css_files.map { |file| File.read(file) }.join("\n\n")
    end

    def serve_components_js
      content = concatenate_component_js
      headers = build_cache_headers(content)
      headers["Content-Type"] = "application/javascript; charset=utf-8"

      [200, headers, [content]]
    end

    def serve_custom_css
      custom_path = File.join(docs_path, "_custom", "styles.css")
      return not_found_response unless File.exist?(custom_path)

      content = File.read(custom_path)
      headers = build_cache_headers(content, File.mtime(custom_path))
      headers["Content-Type"] = "text/css; charset=utf-8"

      [200, headers, [content]]
    end

    def serve_custom_js
      custom_path = File.join(docs_path, "_custom", "scripts.js")
      return not_found_response unless File.exist?(custom_path)

      content = File.read(custom_path)
      headers = build_cache_headers(content, File.mtime(custom_path))
      headers["Content-Type"] = "application/javascript; charset=utf-8"

      [200, headers, [content]]
    end

    def concatenate_component_js
      components_dir = File.join(TEMPLATES_ASSETS_PATH, "js", "components")
      return "" unless Dir.exist?(components_dir)

      js_files = Dir.glob(File.join(components_dir, "*.js"))
      js_files.map { |file| File.read(file) }.join("\n\n")
    end

    def detect_content_type(file_path)
      extension = File.extname(file_path)
      CONTENT_TYPES.fetch(extension, "application/octet-stream")
    end

    def build_cache_headers(content, last_modified = nil)
      headers = {
        "Cache-Control" => "public, max-age=#{CACHE_MAX_AGE}",
        "ETag" => %("#{Digest::MD5.hexdigest(content)}")
      }
      headers["Last-Modified"] = last_modified.httpdate if last_modified
      headers
    end

    def forbidden_response
      [403, { "Content-Type" => "text/plain" }, ["403 Forbidden"]]
    end

    def not_found_response
      [404, { "Content-Type" => "text/plain" }, ["404 Not Found"]]
    end
  end
end
