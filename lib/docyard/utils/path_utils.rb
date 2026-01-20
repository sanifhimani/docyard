# frozen_string_literal: true

module Docyard
  module Utils
    module PathUtils
      module_function

      def sanitize_url_path(request_path)
        clean = request_path.to_s.delete_prefix("/").delete_suffix("/")
        clean = "index" if clean.empty?
        clean.delete_suffix(".md")
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
