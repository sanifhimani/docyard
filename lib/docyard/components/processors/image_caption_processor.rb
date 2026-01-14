# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      class ImageCaptionProcessor < BaseProcessor
        IMAGE_ATTRS_PATTERN = /!\[([^\]]*)\]\(([^)]+)\)\{([^}]+)\}/

        self.priority = 5

        def preprocess(content)
          process_images_with_attrs(content)
        end

        private

        def process_images_with_attrs(content)
          content.gsub(IMAGE_ATTRS_PATTERN) do
            alt = Regexp.last_match(1)
            src = Regexp.last_match(2)
            attrs_string = Regexp.last_match(3)

            attrs = parse_attributes(attrs_string)
            build_image_html(alt, src, attrs)
          end
        end

        def parse_attributes(attrs_string)
          attrs = {}

          attrs_string.scan(/(\w+)="([^"]*)"/) do |key, value|
            attrs[key] = value
          end

          attrs[:nozoom] = true if attrs_string.include?("nozoom")

          attrs
        end

        def build_image_html(alt, src, attrs)
          if attrs["caption"]
            build_figure(alt, src, attrs)
          else
            build_img(alt, src, attrs)
          end
        end

        def build_figure(alt, src, attrs)
          "\n\n" \
            "<figure class=\"docyard-figure\" markdown=\"0\">\n" \
            "#{build_img_tag(alt, src, attrs)}\n" \
            "<figcaption>#{escape_html(attrs['caption'])}</figcaption>\n" \
            "</figure>" \
            "\n\n"
        end

        def build_img(alt, src, attrs)
          "\n\n#{build_img_tag(alt, src, attrs)}\n\n"
        end

        def build_img_tag(alt, src, attrs)
          parts = base_img_attrs(alt, src)
          parts.concat(dimension_attrs(attrs))
          parts << "data-no-zoom" if attrs[:nozoom]
          "<img #{parts.join(' ')}>"
        end

        def base_img_attrs(alt, src)
          ["src=\"#{escape_html(src)}\"", "alt=\"#{escape_html(alt)}\""]
        end

        def dimension_attrs(attrs)
          result = []
          result << "width=\"#{escape_html(attrs['width'])}\"" if attrs["width"]
          result << "height=\"#{escape_html(attrs['height'])}\"" if attrs["height"]
          result
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
