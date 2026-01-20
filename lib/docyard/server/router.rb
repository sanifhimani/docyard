# frozen_string_literal: true

require_relative "../utils/path_utils"

module Docyard
  class Router
    attr_reader :docs_path

    def initialize(docs_path:)
      @docs_path = docs_path
    end

    def resolve(request_path)
      clean_path = sanitize_path(request_path)

      file_path = safe_file_path("#{clean_path}#{Constants::MARKDOWN_EXTENSION}")
      return ResolutionResult.found(file_path) if file_path && File.file?(file_path)

      index_path = safe_file_path(File.join(clean_path, "#{Constants::INDEX_FILE}#{Constants::MARKDOWN_EXTENSION}"))
      return ResolutionResult.found(index_path) if index_path && File.file?(index_path)

      ResolutionResult.not_found
    end

    private

    def sanitize_path(request_path)
      Utils::PathUtils.sanitize_url_path(request_path)
    end

    def safe_file_path(relative_path)
      Utils::PathUtils.resolve_safe_path(relative_path, docs_path)
    end
  end
end
