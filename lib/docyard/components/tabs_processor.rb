# frozen_string_literal: true

require_relative "../renderer"
require_relative "base_processor"
require "kramdown"
require "kramdown-parser-gfm"
require "securerandom"

module Docyard
  module Components
    class TabsProcessor < BaseProcessor
      self.priority = 15

      def preprocess(content)
        return content unless content.include?(":::tabs")

        process_tabs_blocks(content)
      end

      private

      def process_tabs_blocks(content)
        content.gsub(/^:::[ \t]*tabs[ \t]*\n(.*?)^:::[ \t]*$/m) do
          tabs_content = Regexp.last_match(1)
          process_single_tabs_block(tabs_content)
        end
      end

      def process_single_tabs_block(tabs_content)
        tabs = parse_tabs(tabs_content)
        return "" if tabs.empty?

        tabs_html = render_tabs_html(tabs)
        wrap_in_nomarkdown(tabs_html)
      end

      def parse_tabs(content)
        content.split(/^==[ \t]+/).filter_map do |section|
          parse_single_tab(section)
        end
      end

      def parse_single_tab(section)
        return nil if section.strip.empty?

        parts = section.split("\n", 2)
        tab_name = parts[0]&.strip
        return nil if tab_name.nil? || tab_name.empty?

        tab_content = parts[1]&.strip || ""
        content_html = render_markdown_content(tab_content)

        {
          name: tab_name,
          content: content_html
        }
      end

      def render_markdown_content(markdown_content)
        return "" if markdown_content.empty?

        Kramdown::Document.new(
          markdown_content,
          input: "GFM",
          hard_wrap: false,
          syntax_highlighter: "rouge"
        ).to_html
      end

      def render_tabs_html(tabs)
        group_id = SecureRandom.hex(4)

        renderer = Renderer.new
        renderer.render_partial(
          "_tabs", {
            tabs: tabs,
            group_id: group_id
          }
        )
      end

      def wrap_in_nomarkdown(html)
        "{::nomarkdown}\n#{html}\n{:/nomarkdown}"
      end
    end
  end
end
