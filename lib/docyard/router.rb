# frozen_string_literal: true

module Docyard
  class Router
    attr_reader :docs_path

    def initialize(docs_path:)
      @docs_path = docs_path
    end

    def resolve(request_path)
      clean_path = sanitize_path(request_path)

      file_path = File.join(docs_path, "#{clean_path}#{Constants::MARKDOWN_EXTENSION}")
      return Routing::ResolutionResult.found(file_path) if File.file?(file_path)

      index_path = File.join(docs_path, clean_path, "#{Constants::INDEX_FILE}#{Constants::MARKDOWN_EXTENSION}")
      return Routing::ResolutionResult.found(index_path) if File.file?(index_path)

      Routing::ResolutionResult.not_found
    end

    private

    def sanitize_path(request_path)
      clean = request_path.delete_prefix("/")
      clean = Constants::INDEX_FILE if clean.empty?
      clean.delete_suffix(Constants::MARKDOWN_EXTENSION)
    end
  end
end
