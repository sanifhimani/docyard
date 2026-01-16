# frozen_string_literal: true

require_relative "../base_processor"
require_relative "../support/markdown_code_block_helper"

module Docyard
  module Components
    module Processors
      class TooltipProcessor < BaseProcessor
        include Support::MarkdownCodeBlockHelper

        TOOLTIP_PATTERN = /:tooltip\[([^\]]+)\]\{([^}]+)\}/
        self.priority = 6

        def preprocess(content)
          process_outside_code_blocks(content) do |segment|
            segment.gsub(TOOLTIP_PATTERN) do |_match|
              term = ::Regexp.last_match(1)
              attributes = parse_attributes(::Regexp.last_match(2))
              build_tooltip_tag(term, attributes)
            end
          end
        end

        private

        def parse_attributes(attr_string)
          attributes = {}
          attr_string.scan(/(\w+)="([^"]*)"/) do |key, value|
            attributes[key.to_sym] = value
          end
          attributes
        end

        def build_tooltip_tag(term, attributes)
          description = escape_html(attributes[:description] || "")
          link = attributes[:link]
          link_text = attributes[:link_text] || "Learn more"

          data_attrs = %(data-description="#{description}")
          data_attrs += %( data-link="#{escape_html(link)}") if link
          data_attrs += %( data-link-text="#{escape_html(link_text)}") if link

          %(<span class="docyard-tooltip" #{data_attrs}>#{term}</span>)
        end

        def escape_html(text)
          text.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub('"', "&quot;")
        end
      end
    end
  end
end
