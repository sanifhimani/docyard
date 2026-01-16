# frozen_string_literal: true

require_relative "../../rendering/icons"
require_relative "../../rendering/renderer"
require_relative "../base_processor"
require_relative "../support/markdown_code_block_helper"
require "kramdown"
require "kramdown-parser-gfm"

module Docyard
  module Components
    module Processors
      class AccordionProcessor < BaseProcessor
        include Support::MarkdownCodeBlockHelper

        self.priority = 10

        DETAILS_PATTERN = /^:::details(?:\{([^}]*)\})?\s*\n(.*?)^:::\s*$/m

        def preprocess(markdown)
          @code_block_ranges = find_code_block_ranges(markdown)

          markdown.gsub(DETAILS_PATTERN) do
            match = Regexp.last_match
            next match[0] if inside_code_block?(match.begin(0), @code_block_ranges)

            attributes = parse_attributes(match[1])
            content_markdown = match[2]

            title = attributes["title"] || "Details"
            open = attributes.key?("open")
            content_html = render_markdown_content(content_markdown.strip)

            wrap_in_nomarkdown(render_accordion_html(title, content_html, open))
          end
        end

        private

        def parse_attributes(attr_string)
          return {} if attr_string.nil? || attr_string.empty?

          attrs = {}
          attr_string.scan(/(\w+)(?:="([^"]*)")?/) do |key, value|
            attrs[key] = value || true
          end
          attrs
        end

        def render_markdown_content(content_markdown)
          return "" if content_markdown.empty?

          Kramdown::Document.new(
            content_markdown,
            input: "GFM",
            hard_wrap: false,
            syntax_highlighter: "rouge"
          ).to_html
        end

        def wrap_in_nomarkdown(html)
          "{::nomarkdown}\n#{html}\n{:/nomarkdown}"
        end

        def render_accordion_html(title, content_html, open)
          icon_svg = Icons.render("caret-right") || ""
          renderer = Renderer.new

          renderer.render_partial(
            "_accordion", {
              title: title,
              content_html: content_html,
              icon_svg: icon_svg,
              open: open
            }
          )
        end
      end
    end
  end
end
