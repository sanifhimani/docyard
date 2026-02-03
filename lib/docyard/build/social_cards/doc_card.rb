# frozen_string_literal: true

require_relative "card_renderer"

module Docyard
  module Build
    module SocialCards
      class DocCard < CardRenderer
        SECTION_LABEL_SIZE = 26
        TITLE_SIZE = 92
        DESCRIPTION_SIZE = 30

        SECTION_TO_TITLE_GAP = 16
        TITLE_TO_DESC_GAP = 24

        LOGO_AREA_HEIGHT = 160

        TITLE_MAX_CHARS = 22
        DESCRIPTION_MAX_CHARS = 70

        def initialize(config, title:, section: nil, description: nil)
          super(config)
          @title = truncate_text(title, TITLE_MAX_CHARS)
          @section = section
          @description = truncate_text(description, DESCRIPTION_MAX_CHARS)
        end

        protected

        def content_svg
          start_y = calculate_start_y
          elements = []
          y_pos = start_y

          if @section && !@section.empty?
            elements << section_svg(y_pos)
            y_pos += SECTION_TO_TITLE_GAP + TITLE_SIZE
          else
            y_pos += TITLE_SIZE
          end

          elements << title_svg(y_pos)

          if @description && !@description.empty?
            y_pos += TITLE_TO_DESC_GAP + DESCRIPTION_SIZE
            elements << description_svg(y_pos)
          end

          elements.join("\n")
        end

        private

        def calculate_start_y
          total_height = calculate_content_height
          available_height = HEIGHT - LOGO_AREA_HEIGHT
          (available_height - total_height) / 2
        end

        def calculate_content_height
          height = TITLE_SIZE
          height += SECTION_LABEL_SIZE + SECTION_TO_TITLE_GAP if @section && !@section.empty?
          height += TITLE_TO_DESC_GAP + DESCRIPTION_SIZE if @description && !@description.empty?
          height
        end

        def section_svg(y_pos)
          section_text = escape_xml(@section.upcase)
          <<~SVG
            <text x="#{PADDING}" y="#{y_pos}" class="inter" font-size="#{SECTION_LABEL_SIZE}" font-weight="600" fill="#{brand_color}" letter-spacing="0.5">#{section_text}</text>
          SVG
        end

        def title_svg(y_pos)
          title_text = escape_xml(@title)
          <<~SVG
            <text x="#{PADDING}" y="#{y_pos}" class="inter" font-size="#{TITLE_SIZE}" font-weight="800" fill="#{WHITE}" letter-spacing="-0.02em">#{title_text}</text>
          SVG
        end

        def description_svg(y_pos)
          desc_text = escape_xml(@description)
          <<~SVG
            <text x="#{PADDING}" y="#{y_pos}" class="inter" font-size="#{DESCRIPTION_SIZE}" font-weight="400" fill="#{GRAY}">#{desc_text}</text>
          SVG
        end

        def truncate_text(text, max_chars)
          return nil if text.nil?
          return text if text.length <= max_chars

          "#{text[0, max_chars - 3].strip}..."
        end
      end
    end
  end
end
