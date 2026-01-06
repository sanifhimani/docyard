# frozen_string_literal: true

module Docyard
  class AssetHandler
    ASSETS_PATH = File.join(__dir__, "../templates", "assets")
    USER_ASSETS_PATH = "docs/assets"

    CONTENT_TYPES = {
      ".css" => "text/css; charset=utf-8",
      ".js" => "application/javascript; charset=utf-8",
      ".png" => "image/png",
      ".jpg" => "image/jpeg",
      ".jpeg" => "image/jpeg",
      ".svg" => "image/svg+xml",
      ".woff" => "font/woff",
      ".woff2" => "font/woff2",
      ".ttf" => "font/ttf",
      ".ico" => "image/x-icon"
    }.freeze

    def serve(request_path)
      asset_path = extract_asset_path(request_path)

      return forbidden_response if directory_traversal?(asset_path)

      return serve_components_css if asset_path == "css/components.css"
      return serve_components_js if asset_path == "js/components.js"

      file_path = build_file_path(asset_path)
      return not_found_response unless File.file?(file_path)

      serve_file(file_path)
    end

    private

    def extract_asset_path(request_path)
      request_path.delete_prefix("/assets/")
    end

    def directory_traversal?(path)
      path.include?("..")
    end

    def build_file_path(asset_path)
      user_path = File.join(USER_ASSETS_PATH, asset_path)
      return user_path if File.file?(user_path)

      File.join(ASSETS_PATH, asset_path)
    end

    def serve_file(file_path)
      content = File.read(file_path)
      content_type = detect_content_type(file_path)

      [200, { "Content-Type" => content_type }, [content]]
    end

    def serve_components_css
      content = concatenate_component_css
      [200, { "Content-Type" => "text/css; charset=utf-8" }, [content]]
    end

    def concatenate_component_css
      components_dir = File.join(ASSETS_PATH, "css", "components")
      return "" unless Dir.exist?(components_dir)

      css_files = Dir.glob(File.join(components_dir, "*.css"))
      css_files.map { |file| File.read(file) }.join("\n\n")
    end

    def serve_components_js
      content = concatenate_component_js
      [200, { "Content-Type" => "application/javascript; charset=utf-8" }, [content]]
    end

    def concatenate_component_js
      components_dir = File.join(ASSETS_PATH, "js", "components")
      return "" unless Dir.exist?(components_dir)

      js_files = Dir.glob(File.join(components_dir, "*.js"))
      js_files.map { |file| File.read(file) }.join("\n\n")
    end

    def detect_content_type(file_path)
      extension = File.extname(file_path)
      CONTENT_TYPES.fetch(extension, "application/octet-stream")
    end

    def forbidden_response
      [403, { "Content-Type" => "text/plain" }, ["403 Forbidden"]]
    end

    def not_found_response
      [404, { "Content-Type" => "text/plain" }, ["404 Not Found"]]
    end
  end
end
