# frozen_string_literal: true

module Docyard
  module Utils
    module UrlHelpers
      def normalize_base_url(url)
        return "/" if url.nil? || url.empty?

        url = "/#{url}" unless url.start_with?("/")
        url.end_with?("/") ? url : "#{url}/"
      end

      def link_path(path)
        return path if path.nil? || path.start_with?("http://", "https://")

        "#{base_url.chomp('/')}#{path}"
      end
    end
  end
end
