# frozen_string_literal: true

require "rack/mime"

module Docyard
  class StaticFileApp
    def initialize(root)
      @root = root
    end

    def call(env)
      path = env["PATH_INFO"]
      file_path = File.join(@root, path)

      if path.end_with?("/") || File.directory?(file_path)
        index_path = File.join(file_path, "index.html")
        return serve_file(index_path) if File.file?(index_path)
      elsif File.file?(file_path)
        return serve_file(file_path)
      end

      serve_not_found
    end

    private

    def serve_file(path)
      content = File.read(path)
      content_type = Rack::Mime.mime_type(File.extname(path), "application/octet-stream")
      [200, { "content-type" => content_type }, [content]]
    end

    def serve_not_found
      error_page = File.join(@root, "404.html")
      if File.file?(error_page)
        [404, { "content-type" => "text/html; charset=utf-8" }, [File.read(error_page)]]
      else
        [404, { "content-type" => "text/plain" }, ["Not Found"]]
      end
    end
  end
end
