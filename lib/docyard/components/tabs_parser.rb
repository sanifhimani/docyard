# frozen_string_literal: true

require_relative "icon_detector"
require "kramdown"
require "kramdown-parser-gfm"

module Docyard
  module Components
    class TabsParser
      def self.parse(content)
        new(content).parse
      end

      def initialize(content)
        @content = content
      end

      def parse
        sections.filter_map { |section| parse_section(section) }
      end

      private

      attr_reader :content

      def sections
        content.split(/^==[ \t]+/)
      end

      def parse_section(section)
        return nil if section.strip.empty?

        parts = section.split("\n", 2)
        tab_name = parts[0]&.strip
        return nil if tab_name.nil? || tab_name.empty?

        tab_content = parts[1]&.strip || ""
        icon_data = IconDetector.detect(tab_name, tab_content)

        {
          name: icon_data[:name],
          content: render_markdown(tab_content),
          icon: icon_data[:icon],
          icon_source: icon_data[:icon_source]
        }
      end

      def render_markdown(markdown_content)
        return "" if markdown_content.empty?

        Kramdown::Document.new(
          markdown_content,
          input: "GFM",
          hard_wrap: false,
          syntax_highlighter: "rouge"
        ).to_html
      end
    end
  end
end
