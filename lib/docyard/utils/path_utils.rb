# frozen_string_literal: true

require "uri"

module Docyard
  module Utils
    module PathUtils
      module_function

      def sanitize_url_path(request_path)
        decoded = decode_path(request_path)
        clean = decoded.delete_prefix("/").delete_suffix("/")
        clean = "index" if clean.empty?
        clean.delete_suffix(".md")
      end

      def safe_path?(requested_path, base_dir)
        return false if requested_path.nil? || base_dir.nil?

        expanded_base = File.expand_path(base_dir)
        expanded_path = File.expand_path(requested_path, base_dir)
        expanded_path.start_with?("#{expanded_base}/") || expanded_path == expanded_base
      end

      def resolve_safe_path(relative_path, base_dir)
        return nil if relative_path.nil? || base_dir.nil?

        decoded = decode_path(relative_path)
        full_path = File.join(base_dir, decoded)
        expanded = File.expand_path(full_path)
        expanded_base = File.expand_path(base_dir)

        return nil unless expanded.start_with?("#{expanded_base}/")

        expanded
      end

      def decode_path(path)
        decoded = URI.decode_www_form_component(path.to_s)
        decoded.gsub(/\\+/, "/")
      rescue ArgumentError
        path.to_s
      end

      def markdown_file_to_url(file_path, docs_path)
        relative_path = file_path.delete_prefix("#{docs_path}/")
        relative_path_to_url(relative_path)
      end

      def relative_path_to_url(relative_path)
        base_name = File.basename(relative_path, ".md")
        dir_name = File.dirname(relative_path)

        if base_name == "index"
          dir_name == "." ? "/" : "/#{dir_name}"
        else
          dir_name == "." ? "/#{base_name}" : "/#{dir_name}/#{base_name}"
        end
      end

      def markdown_to_html_output(relative_path, output_dir)
        base_name = File.basename(relative_path, ".md")
        dir_name = File.dirname(relative_path)

        if base_name == "index"
          File.join(output_dir, dir_name, "index.html")
        else
          File.join(output_dir, dir_name, base_name, "index.html")
        end
      end
    end
  end
end
