# frozen_string_literal: true

require "rack/mime"

module Docyard
  class StaticFileApp
    def initialize(root, base_path: "/")
      @root = root
      @base_path = base_path.chomp("/")
    end

    def call(env)
      path = env["PATH_INFO"]

      return serve_not_found unless path_under_base?(path)

      relative_path = strip_base_path(path)
      file_path = File.join(@root, relative_path)

      if relative_path.end_with?("/") || relative_path.empty? || File.directory?(file_path)
        index_path = File.join(file_path, "index.html")
        return serve_file(index_path) if File.file?(index_path)
      elsif File.file?(file_path)
        return serve_file(file_path)
      end

      serve_not_found
    end

    private

    def path_under_base?(path)
      return true if @base_path.empty?

      path == @base_path || path.start_with?("#{@base_path}/")
    end

    def strip_base_path(path)
      return path if @base_path.empty?

      path.delete_prefix(@base_path)
    end

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
