# frozen_string_literal: true

require "time"

module Docyard
  module Build
    class SitemapGenerator
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def generate
        urls = collect_urls
        sitemap_content = build_sitemap(urls)

        output_path = File.join(config.build.output, "sitemap.xml")
        File.write(output_path, sitemap_content)

        Docyard.logger.info("[✓] Generated sitemap.xml (#{urls.size} URLs)")
      end

      private

      def collect_urls
        html_files = Dir.glob(File.join(config.build.output, "**", "index.html"))

        html_files.map do |file|
          relative_path = file.delete_prefix(config.build.output).delete_suffix("/index.html")
          url_path = relative_path.empty? ? "/" : relative_path
          lastmod = File.mtime(file).utc.iso8601

          { loc: url_path, lastmod: lastmod }
        end
      end

      def build_sitemap(urls)
        base = config.build.base
        base = base.chop if base.end_with?("/")

        xml = ['<?xml version="1.0" encoding="UTF-8"?>']
        xml << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'

        urls.each do |url|
          xml << "  <url>"
          xml << "    <loc>#{base}#{url[:loc]}</loc>"
          xml << "    <lastmod>#{url[:lastmod]}</lastmod>"
          xml << "  </url>"
        end

        xml << "</urlset>"
        xml.join("\n")
      end
    end
  end
end
