# frozen_string_literal: true

module Docyard
  class PagefindHandler
    CONTENT_TYPES = {
      ".js" => "application/javascript; charset=utf-8",
      ".css" => "text/css; charset=utf-8",
      ".json" => "application/json; charset=utf-8"
    }.freeze

    def initialize(pagefind_path:, config:)
      @pagefind_path = pagefind_path
      @config = config
    end

    def serve(path)
      relative_path = path.delete_prefix(Constants::PAGEFIND_PREFIX)
      return not_found if relative_path.include?("..")

      file_path = resolve_file(relative_path)
      return not_found unless file_path && File.file?(file_path)

      serve_file(file_path)
    end

    private

    attr_reader :pagefind_path, :config

    def resolve_file(relative_path)
      return File.join(pagefind_path, relative_path) if pagefind_path && Dir.exist?(pagefind_path)

      output_dir = config&.build&.output_dir || "dist"
      File.join(output_dir, "pagefind", relative_path)
    end

    def serve_file(file_path)
      content = File.binread(file_path)
      content_type = content_type_for(file_path)

      [Constants::STATUS_OK, build_headers(content_type), [content]]
    end

    def build_headers(content_type)
      {
        "Content-Type" => content_type,
        "Cache-Control" => "no-cache, no-store, must-revalidate",
        "Pragma" => "no-cache",
        "Expires" => "0"
      }
    end

    def content_type_for(file_path)
      extension = File.extname(file_path)
      CONTENT_TYPES.fetch(extension, "application/octet-stream")
    end

    def not_found
      message = "Pagefind not found. Run 'docyard build' first."
      [Constants::STATUS_NOT_FOUND, { "Content-Type" => "text/plain" }, [message]]
    end
  end
end
