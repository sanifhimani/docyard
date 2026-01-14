# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      class CustomAnchorProcessor < BaseProcessor
        CUSTOM_ID_PATTERN = /\s*\{#([\w-]+)\}\s*$/

        self.priority = 25

        def postprocess(html)
          process_custom_anchors(html)
        end

        private

        def process_custom_anchors(html)
          html.gsub(%r{<(h[1-6])(\s+id="[^"]*")?>(.+?)</\1>}m) do
            tag = Regexp.last_match(1)
            existing_attr = Regexp.last_match(2) || ""
            content = Regexp.last_match(3)

            if content.match?(CUSTOM_ID_PATTERN)
              process_heading_with_custom_id(tag, content)
            else
              "<#{tag}#{existing_attr}>#{content}</#{tag}>"
            end
          end
        end

        def process_heading_with_custom_id(tag, content)
          custom_id = content.match(CUSTOM_ID_PATTERN)[1]
          clean_content = content.sub(CUSTOM_ID_PATTERN, "")

          "<#{tag} id=\"#{custom_id}\">#{clean_content}</#{tag}>"
        end
      end
    end
  end
end
