# frozen_string_literal: true

module Docyard
  module Components
    class HeadingAnchorProcessor < BaseProcessor
      self.priority = 30

      def postprocess(html)
        add_anchor_links(html)
      end

      private

      def add_anchor_links(html)
        html.gsub(%r{<(h[2-6])\s+id="([^"]+)">(.*?)</\1>}m) do |_match|
          tag = Regexp.last_match(1)
          id = Regexp.last_match(2)
          content = Regexp.last_match(3)

          anchor_html = render_anchor_link(id)

          "<#{tag} id=\"#{id}\">#{content}#{anchor_html}</#{tag}>"
        end
      end

      def render_anchor_link(id)
        renderer = Renderer.new
        renderer.render_partial("_heading_anchor", {
                                  id: id
                                })
      end
    end
  end
end
