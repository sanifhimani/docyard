# frozen_string_literal: true

require "cssminify"
require "terser"
require "digest"

module Docyard
  module Build
    class AssetBundler
      ASSETS_PATH = File.join(__dir__, "..", "templates", "assets")

      attr_reader :config, :verbose

      def initialize(config, verbose: false)
        @config = config
        @verbose = verbose
      end

      def bundle
        puts "\nBundling assets..."

        css_hash = bundle_css
        js_hash = bundle_js

        update_html_references(css_hash, js_hash)

        2
      end

      private

      def bundle_css
        log "  Bundling CSS..."

        main_css = File.read(File.join(ASSETS_PATH, "css", "main.css"))
        css_content = resolve_css_imports(main_css)
        minified = CSSminify.compress(css_content)
        minified = fix_calc_whitespace(minified)
        hash = generate_hash(minified)

        write_bundled_asset(minified, hash, "css")
        log_compression_stats(css_content, minified, "CSS")

        hash
      end

      def fix_calc_whitespace(css)
        css
          .gsub(/\)\+(?!\s)/, ") + ")
          .gsub(/\)-(?![-\s])/, ") - ")
          .gsub(/(\d[a-z]*)\+(?=[\w(])/, '\1 + ')
          .gsub(/([lch])\+(?=[\d.])/, '\1 + ')
          .gsub(/([lch])-(?=[\d.])/, '\1 - ')
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
        log "  Bundling JS..."

        theme_js = File.read(File.join(ASSETS_PATH, "js", "theme.js"))
        components_js = concatenate_component_js
        js_content = [theme_js, components_js].join("\n")
        minified = Terser.compile(js_content)
        hash = generate_hash(minified)

        write_bundled_asset(minified, hash, "js")
        log_compression_stats(js_content, minified, "JS")

        hash
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

        log "  [✓] Updated asset references in #{html_files.size} HTML files"
      end

      def replace_asset_references(content, css_hash, js_hash, base_url)
        content.gsub(%r{/_docyard/css/main\.css}, "#{base_url}_docyard/bundle.#{css_hash}.css")
          .gsub(%r{/_docyard/js/theme\.js}, "#{base_url}_docyard/bundle.#{js_hash}.js")
          .gsub(%r{/_docyard/js/components\.js}, "")
          .gsub(%r{<script src="/_docyard/js/reload\.js"></script>}, "")
      end

      def write_bundled_asset(content, hash, extension)
        filename = "bundle.#{hash}.#{extension}"
        output_path = File.join(config.build.output, "_docyard", filename)
        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, content)
      end

      def log_compression_stats(original, minified, label)
        original_size = (original.bytesize / 1024.0).round(1)
        minified_size = (minified.bytesize / 1024.0).round(1)
        reduction = (((original_size - minified_size) / original_size) * 100).round(0)
        log "  [✓] #{label}: #{original_size} KB -> #{minified_size} KB (-#{reduction}%)"
      end

      def normalize_base_url(url)
        return "/" if url.nil? || url.empty? || url == "/"

        url = "/#{url}" unless url.start_with?("/")
        url.end_with?("/") ? url : "#{url}/"
      end

      def log(message)
        puts message
      end
    end
  end
end
