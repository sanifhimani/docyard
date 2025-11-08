# frozen_string_literal: true

module Docyard
  module Utils
    class PathResolver
      def self.normalize(path)
        return "/" if path.nil? || path.empty?

        normalized = path.delete_suffix(".md")
          .delete_suffix("/index")

        normalized = "" if normalized == "index"

        normalized = "/" if normalized.empty?
        normalized = "/#{normalized}" unless normalized.start_with?("/")
        normalized
      end

      def self.to_url(relative_path)
        normalize(relative_path)
      end

      def self.ancestor?(parent_path, child_path)
        return false if parent_path.nil?

        child_path.start_with?(parent_path) && child_path != parent_path
      end
    end
  end
end
