# frozen_string_literal: true

require "cssminify"
require "terser"
require "digest"

module Docyard
  module Build
    class AssetBundler
      include Utils::UrlHelpers

      ASSETS_PATH = File.join(__dir__, "..", "templates", "assets")

      attr_reader :config, :verbose

      def initialize(config, verbose: false)
        @config = config
        @verbose = verbose
      end

      def bundle
        css_hash, css_size = bundle_css
        js_hash, js_size = bundle_js

        update_html_references(css_hash, js_hash)

        [css_size, js_size]
      end

      private

      def bundle_css
        main_css = File.read(File.join(ASSETS_PATH, "css", "main.css"))
        css_content = resolve_css_imports(main_css)
        minified = CSSminify.compress(css_content)
        minified = fix_calc_whitespace(minified)
        minified = fix_css_math_functions(minified)
        minified = replace_css_asset_urls(minified)
        hash = generate_hash(minified)

        write_bundled_asset(minified, hash, "css")

        [hash, minified.bytesize]
      end

      def fix_calc_whitespace(css)
        css
          .gsub(/\)\+(?!\s)/, ") + ")
          .gsub(/\)-(?![-\s])/, ") - ")
          .gsub(/(\d[a-z]*)\+(?=[\w(])/, '\1 + ')
          .gsub(/([lch])\+(?=[\d.])/, '\1 + ')
          .gsub(/([lch])-(?=[\d.])/, '\1 - ')
      end

      def fix_css_math_functions(css)
        css.gsub(/\bmax\(0,/, "max(0px,").gsub(/\bmin\(0,/, "min(0px,)")
      end

      def replace_css_asset_urls(css)
        base_url = normalize_base_url(config.build.base)
        css.gsub(%r{/_docyard/fonts/}, "#{base_url}_docyard/fonts/")
      end

      def resolve_css_imports(css_content)
        css_content.gsub(/@import url\('([^']+)'\);/) do |match|
          import_file = Regexp.last_match(1)

          if import_file == "components.css"
            concatenate_component_css
          else
            file_path = File.join(ASSETS_PATH, "css", import_file)
            File.exist?(file_path) ? File.read(file_path) : match
          end
        end
      end

      def concatenate_component_css
        components_dir = File.join(ASSETS_PATH, "css", "components")
        return "" unless Dir.exist?(components_dir)

        css_files = Dir.glob(File.join(components_dir, "*.css"))
        css_files.map { |file| File.read(file) }.join("\n\n")
      end

      def bundle_js
        theme_js = File.read(File.join(ASSETS_PATH, "js", "theme.js"))
        components_js = concatenate_component_js
        js_content = [theme_js, components_js].join("\n")
        minified = Terser.compile(js_content)
        minified = replace_js_asset_urls(minified)
        hash = generate_hash(minified)

        write_bundled_asset(minified, hash, "js")

        [hash, minified.bytesize]
      end

      def replace_js_asset_urls(js_content)
        base_url = normalize_base_url(config.build.base)
        js_content.gsub(%r{"/_docyard/pagefind/}, "\"#{base_url}_docyard/pagefind/")
          .gsub(%r{baseUrl:\s*["']/["']}, "baseUrl:\"#{base_url}\"")
      end

      def concatenate_component_js
        components_dir = File.join(ASSETS_PATH, "js", "components")
        return "" unless Dir.exist?(components_dir)

        js_files = Dir.glob(File.join(components_dir, "*.js"))
        js_files.map { |file| File.read(file) }.join("\n\n")
      end

      def generate_hash(content)
        Digest::MD5.hexdigest(content)[0..7]
      end

      def update_html_references(css_hash, js_hash)
        html_files = Dir.glob(File.join(config.build.output, "**", "*.html"))
        base_url = normalize_base_url(config.build.base)

        html_files.each do |file|
          content = replace_asset_references(File.read(file), css_hash, js_hash, base_url)
          File.write(file, content)
        end
      end

      def replace_asset_references(content, css_hash, js_hash, base_url)
        content.gsub(%r{/_docyard/css/main\.css}, "#{base_url}_docyard/bundle.#{css_hash}.css")
          .gsub(%r{/_docyard/js/theme\.js}, "#{base_url}_docyard/bundle.#{js_hash}.js")
          .gsub(%r{/_docyard/js/components\.js}, "")
          .gsub(%r{<script src="/_docyard/js/reload\.js"></script>}, "")
          .then { |html| replace_content_image_paths(html, base_url) }
      end

      def replace_content_image_paths(content, base_url)
        return content if base_url == "/"

        base_path_pattern = Regexp.escape(base_url.delete_prefix("/"))
        content.gsub(%r{(<img[^>]*\ssrc=")/(?!_docyard/|#{base_path_pattern})([^"]*")}) do
          "#{Regexp.last_match(1)}#{base_url}#{Regexp.last_match(2)}"
        end
      end

      def write_bundled_asset(content, hash, extension)
        filename = "bundle.#{hash}.#{extension}"
        output_path = File.join(config.build.output, "_docyard", filename)
        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, content)
      end
    end
  end
end
