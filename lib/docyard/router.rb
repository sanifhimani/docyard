# frozen_string_literal: true

module Docyard
  class Router
    attr_reader :docs_path

    def initialize(docs_path:)
      @docs_path = docs_path
    end

    def resolve(request_path)
      clean_path = request_path.delete_prefix("/")
      clean_path = "index" if clean_path.empty?

      clean_path = clean_path.delete_suffix(".md")

      file_path = File.join(docs_path, "#{clean_path}.md")
      return file_path if File.file?(file_path)

      index_path = File.join(docs_path, clean_path, "index.md")
      return index_path if File.file?(index_path)

      nil
    end
  end
end
