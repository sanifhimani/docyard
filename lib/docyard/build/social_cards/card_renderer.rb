# frozen_string_literal: true

require "vips"

module Docyard
  module Build
    module SocialCards
      class CardRenderer
        WIDTH = 1200
        HEIGHT = 630
        BACKGROUND_COLOR = "#121212"
        DEFAULT_BRAND_COLOR = "#22D3EE"
        WHITE = "#FFFFFF"
        GRAY = "#71717A"

        PADDING = 88
        LOGO_BOTTOM_OFFSET = 88

        LOGO_ICON_WIDTH = 40
        LOGO_ICON_HEIGHT = 58
        LOGO_TEXT_SIZE = 28
        LOGO_GAP = 16

        attr_reader :config

        def initialize(config)
          @config = config
        end

        def render(output_path)
          svg_content = build_svg
          save_as_png(svg_content, output_path)
        end

        protected

        def build_svg
          <<~SVG
            <svg xmlns="http://www.w3.org/2000/svg" width="#{WIDTH}" height="#{HEIGHT}" viewBox="0 0 #{WIDTH} #{HEIGHT}">
              <defs>
                <style>
                  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&amp;display=swap');
                  .inter { font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
                </style>
              </defs>
              <rect width="#{WIDTH}" height="#{HEIGHT}" fill="#{BACKGROUND_COLOR}"/>
              #{content_svg}
              #{logo_svg}
            </svg>
          SVG
        end

        def content_svg
          raise NotImplementedError, "Subclasses must implement content_svg"
        end

        def logo_svg
          site_title = escape_xml(config.title || "Docyard")
          logo_y = HEIGHT - LOGO_BOTTOM_OFFSET
          logo_x, text_anchor = logo_position_and_anchor

          <<~SVG
            <g transform="translate(#{logo_x}, #{logo_y})">
              #{logo_icon_svg(0, -LOGO_ICON_HEIGHT)}
              <text x="#{LOGO_ICON_WIDTH + LOGO_GAP}" y="-#{(LOGO_ICON_HEIGHT / 2) - 10}" class="inter" font-size="#{LOGO_TEXT_SIZE}" font-weight="700" fill="#{WHITE}" text-anchor="#{text_anchor}">#{site_title}</text>
            </g>
          SVG
        end

        def logo_position_and_anchor
          [PADDING, "start"]
        end

        def logo_icon_svg(x_offset, y_offset)
          color = brand_color
          scale = LOGO_ICON_WIDTH.to_f / 531
          <<~SVG
            <g transform="translate(#{x_offset}, #{y_offset}) scale(#{scale})">
              <path fill="#{color}" d="M359.643 59.1798C402.213 89.4398 449.713 123.6 502.063 160.99C510.793 167.23 515.873 170.31 519.293 178.05C523.253 187.02 521.733 198.11 515.883 205.77C513.77 208.536 510.93 211.2 507.363 213.76C379.643 305.353 309.413 355.73 296.673 364.89C287.987 371.136 282.07 374.8 278.923 375.88C269.703 379.026 260.263 378.636 250.603 374.71C248.243 373.75 244.497 371.416 239.363 367.71C199.963 339.29 177.32 322.99 171.433 318.81C128.863 288.54 81.3733 254.39 29.0233 216.99C20.2833 210.75 15.2033 207.67 11.7833 199.93C7.82332 190.96 9.34332 179.87 15.1933 172.21C17.3067 169.443 20.1467 166.78 23.7133 164.22C151.433 72.6264 221.663 22.2498 234.403 13.0898C243.09 6.84309 249.007 3.17976 252.153 2.09976C261.373 -1.04691 270.813 -0.656912 280.473 3.26976C282.833 4.22976 286.58 6.56309 291.713 10.2698C331.113 38.6898 353.757 54.9931 359.643 59.1798Z"/>
              <path fill="#{WHITE}" d="M467.383 298.01C483.943 286.23 505.033 289.93 519.063 303.51C524.457 308.723 528.033 314.713 529.793 321.48C530.433 323.92 530.733 330.946 530.693 342.56C530.647 356.206 530.657 427.233 530.723 555.64C530.723 566.633 530.513 573 530.093 574.74C527.033 587.29 518.333 592.61 506.693 601.06C504.313 602.786 430.877 656.346 286.383 761.74C275.623 769.59 261.793 770.79 250.113 764.36C249.18 763.846 245.86 761.513 240.153 757.36C150.56 692.066 74.8667 637.046 13.0733 592.3C6.70001 587.68 2.65667 581.73 0.943337 574.45C0.316671 571.783 0.00333476 564.803 0.00333476 553.51C-0.00333191 421.323 -4.06895e-06 348.98 0.0133293 336.48C0.0133293 332.84 -0.0766665 327.18 0.783334 323.18C4.59333 305.51 20.1033 293.29 37.4533 291.15C42.9467 290.476 48.8667 291.276 55.2133 293.55C58.28 294.643 63.3533 297.8 70.4333 303.02C75.98 307.113 82.4433 311.78 89.8233 317.02C128.563 344.526 178.703 380.303 240.243 424.35C242.73 426.13 245.853 428.246 249.613 430.7C257.443 435.8 268.453 436.24 277.213 433.14C279.8 432.22 284.54 429.283 291.433 424.33C394.46 350.276 453.11 308.17 467.383 298.01Z"/>
            </g>
          SVG
        end

        def brand_color
          color = config.branding.color
          if color.is_a?(Hash)
            color["dark"] || color["light"] || DEFAULT_BRAND_COLOR
          elsif color.is_a?(String) && !color.strip.empty?
            color.strip
          else
            DEFAULT_BRAND_COLOR
          end
        end

        def escape_xml(text)
          text.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub('"', "&quot;")
            .gsub("'", "&apos;")
        end

        def save_as_png(svg_content, output_path)
          FileUtils.mkdir_p(File.dirname(output_path))
          image = Vips::Image.svgload_buffer(svg_content, dpi: 96)
          image.write_to_file(output_path, compression: 9, palette: true)
        end
      end
    end
  end
end
