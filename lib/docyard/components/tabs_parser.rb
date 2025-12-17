# frozen_string_literal: true

require_relative "icon_detector"
require_relative "../icons"
require_relative "../renderer"
require "kramdown"
require "kramdown-parser-gfm"
require "cgi"

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

        tab_name, tab_content = extract_tab_parts(section)
        return nil if tab_name.nil? || tab_name.empty?

        build_tab_data(tab_name, tab_content)
      end

      def extract_tab_parts(section)
        parts = section.split("\n", 2)
        [parts[0]&.strip, parts[1]&.strip || ""]
      end

      def build_tab_data(tab_name, tab_content)
        icon_data = IconDetector.detect(tab_name, tab_content)
        rendered_content = render_markdown(tab_content)
        enhanced_content = add_copy_buttons_to_code_blocks(rendered_content)

        {
          name: icon_data[:name],
          content: enhanced_content,
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

      def add_copy_buttons_to_code_blocks(html)
        return html unless html.include?('<div class="highlight">')

        html.gsub(%r{<div class="highlight">(.*?)</div>}m) do
          wrap_code_block_with_copy_button(Regexp.last_match)
        end
      end

      def wrap_code_block_with_copy_button(match)
        code_text = extract_code_text(match[1])
        Renderer.new.render_partial("_code_block", code_block_locals(match[0], code_text))
      end

      def code_block_locals(original_html, code_text)
        {
          code_block_html: original_html,
          code_text: escape_html_attribute(code_text),
          copy_icon: Icons.render("copy", "regular") || "",
          show_line_numbers: false,
          line_numbers: [],
          highlights: [],
          diff_lines: {},
          start_line: 1,
          title: nil,
          icon: nil,
          icon_source: nil
        }
      end

      def extract_code_text(html)
        text = html.gsub(/<[^>]+>/, "")
        text = CGI.unescapeHTML(text)
        text.strip
      end

      def escape_html_attribute(text)
        text.gsub('"', "&quot;")
          .gsub("'", "&#39;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
      end
    end
  end
end
