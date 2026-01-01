# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      class TableOfContentsProcessor < BaseProcessor
        self.priority = 35

        def postprocess(html)
          headings = extract_headings(html)
          context[:toc] = headings
          html
        end

        private

        def extract_headings(html)
          headings = []

          html.scan(%r{<(h[2-4])\s+id="([^"]+)">(.*?)</\1>}m) do
            level = Regexp.last_match(1)[1].to_i
            id = Regexp.last_match(2)
            text = strip_html(Regexp.last_match(3))

            headings << {
              level: level,
              id: id,
              text: text
            }
          end

          build_hierarchy(headings)
        end

        def build_hierarchy(headings)
          return [] if headings.empty?

          root = []
          stack = []

          headings.each do |heading|
            heading[:children] = []

            stack.pop while stack.any? && stack.last[:level] >= heading[:level]

            if stack.empty?
              root << heading
            else
              stack.last[:children] << heading
            end

            stack << heading
          end

          root
        end

        def strip_html(text)
          text.gsub(%r{<a[^>]*class="heading-anchor"[^>]*>.*?</a>}, "")
            .gsub(/<[^>]+>/, "")
            .strip
        end
      end
    end
  end
end
