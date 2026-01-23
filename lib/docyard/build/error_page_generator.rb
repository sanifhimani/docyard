# frozen_string_literal: true

module Docyard
  module Build
    class ErrorPageGenerator
      attr_reader :config, :docs_path, :renderer

      def initialize(config:, docs_path:, renderer:)
        @config = config
        @docs_path = docs_path
        @renderer = renderer
      end

      def generate
        output_path = File.join(config.build.output, "404.html")
        html_content = load_content

        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, html_content)
      end

      private

      def load_content
        custom_error_page = File.join(docs_path, "404.html")
        return File.read(custom_error_page) if File.exist?(custom_error_page)

        branding = BrandingResolver.new(config).resolve
        renderer.render_not_found(branding: branding)
      end
    end
  end
end
