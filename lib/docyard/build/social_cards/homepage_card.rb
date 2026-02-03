# frozen_string_literal: true

require_relative "card_renderer"

module Docyard
  module Build
    module SocialCards
      class HomepageCard < CardRenderer
        TITLE_SIZE = 84
        TITLE_MAX_WIDTH = 1024

        def initialize(config, title:)
          super(config)
          @title = title
        end

        protected

        def content_svg
          title_text = escape_xml(@title)
          logo_area = LOGO_ICON_HEIGHT + LOGO_BOTTOM_OFFSET + 40
          title_y = (HEIGHT - logo_area) / 2

          <<~SVG
            #{background_curves}
            <text x="#{WIDTH / 2}" y="#{title_y}" class="inter" font-size="#{TITLE_SIZE}" font-weight="700" fill="#{brand_color}" text-anchor="middle" dominant-baseline="middle">
              #{wrap_text(title_text, TITLE_SIZE, TITLE_MAX_WIDTH)}
            </text>
          SVG
        end

        def background_curves
          <<~SVG
            <g fill="none" stroke="#1f1f1f" stroke-width="4">
              <!-- Top left flowing down -->
              <ellipse cx="-200" cy="-100" rx="500" ry="400"/>
              <ellipse cx="-300" cy="200" rx="600" ry="500"/>
              <!-- Top right diagonal -->
              <ellipse cx="1400" cy="-200" rx="550" ry="450"/>
              <ellipse cx="1100" cy="-300" rx="700" ry="600"/>
              <!-- Bottom crossing -->
              <ellipse cx="200" cy="800" rx="500" ry="400"/>
              <ellipse cx="1000" cy="900" rx="600" ry="450"/>
              <!-- Mid crossing -->
              <ellipse cx="1500" cy="400" rx="450" ry="550"/>
            </g>
          SVG
        end

        def logo_position_and_anchor
          [
            (WIDTH / 2) - ((LOGO_ICON_WIDTH + LOGO_GAP + estimate_text_width(config.title || "Docyard",
                                                                             LOGO_TEXT_SIZE)) / 2), "start"
          ]
        end

        private

        def wrap_text(text, font_size, max_width)
          lines = split_into_lines(text, max_width, font_size)
          lines_to_tspans(lines, font_size)
        end

        def split_into_lines(text, max_width, font_size)
          chars_per_line = (max_width / (font_size * 0.5)).to_i
          words = text.split
          lines = []
          current_line = []

          words.each { |word| current_line, lines = process_word(word, current_line, lines, chars_per_line) }
          lines << current_line.join(" ") if current_line.any?
          lines
        end

        def process_word(word, current_line, lines, chars_per_line)
          test_line = (current_line + [word]).join(" ")
          if test_line.length > chars_per_line && current_line.any?
            lines << current_line.join(" ")
            [[word], lines]
          else
            [current_line + [word], lines]
          end
        end

        def lines_to_tspans(lines, font_size)
          lines.map.with_index do |line, i|
            dy = i.zero? ? 0 : font_size * 1.15
            %(<tspan x="#{WIDTH / 2}" dy="#{dy}">#{line}</tspan>)
          end.join
        end

        def estimate_text_width(text, font_size)
          text.length * font_size * 0.55
        end
      end
    end
  end
end
