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
      class CardsProcessor < BaseProcessor
        include Support::MarkdownCodeBlockHelper

        self.priority = 10

        CARDS_PATTERN = /^:::cards\s*\n(.*?)^:::\s*$/m
        CARD_PATTERN = /^::card\{([^}]*)\}\s*\n(.*?)^::\s*$/m

        def preprocess(markdown)
          @code_block_ranges = find_code_block_ranges(markdown)

          markdown.gsub(CARDS_PATTERN) do
            match = Regexp.last_match
            next match[0] if inside_code_block?(match.begin(0), @code_block_ranges)

            content = match[1]
            cards = parse_cards(content)

            wrap_in_nomarkdown(render_cards_html(cards))
          end
        end

        private

        def parse_cards(content)
          cards = []

          content.scan(CARD_PATTERN) do |attrs_string, card_content|
            attrs = parse_attributes(attrs_string)
            cards << {
              title: attrs["title"] || "Card",
              icon: attrs["icon"],
              href: attrs["href"],
              content: card_content.strip
            }
          end

          cards
        end

        def parse_attributes(attr_string)
          return {} if attr_string.nil? || attr_string.empty?

          attrs = {}
          attr_string.scan(/(\w+)="([^"]*)"/) do |key, value|
            attrs[key] = value
          end
          attrs
        end

        def render_cards_html(cards)
          renderer = Renderer.new

          cards_html = cards.map do |card|
            icon_svg = card[:icon] ? Icons.render(card[:icon]) : nil
            content_html = render_markdown_content(card[:content])

            renderer.render_partial(
              "_card", {
                title: card[:title],
                icon_svg: icon_svg,
                href: card[:href],
                content_html: content_html
              }
            )
          end.join("\n")

          "<div class=\"docyard-cards\">\n#{cards_html}\n</div>"
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
      end
    end
  end
end
