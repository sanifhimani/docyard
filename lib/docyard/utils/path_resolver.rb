# frozen_string_literal: true

module Docyard
  module Utils
    class PathResolver
      def self.normalize(path)
        return "/" if path.nil? || path.empty?

        normalized = path.delete_suffix("/")
          .delete_suffix(".md")
          .delete_suffix("/index")

        normalized = "" if normalized == "index"

        normalized = "/" if normalized.empty?
        normalized = "/#{normalized}" unless normalized.start_with?("/")
        normalized
      end
    end
  end
end
