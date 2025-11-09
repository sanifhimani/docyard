# frozen_string_literal: true

require_relative "../icons"
require_relative "../renderer"
require_relative "base_processor"

module Docyard
  module Components
    class CodeBlockProcessor < BaseProcessor
      self.priority = 20

      def postprocess(html)
        return html unless html.include?('<div class="highlight">')

        html.gsub(%r{<div class="highlight">(.*?)</div>}m) do
          process_code_block(Regexp.last_match(0), Regexp.last_match(1))
        end
      end

      private

      def process_code_block(original_html, inner_html)
        code_text = extract_code_text(inner_html)

        render_code_block_with_copy(original_html, code_text)
      end

      def extract_code_text(html)
        text = html.gsub(/<[^>]+>/, "")
        text = CGI.unescapeHTML(text)
        text.strip
      end

      def render_code_block_with_copy(code_block_html, code_text)
        copy_icon = Icons.render("copy", "regular") || ""
        renderer = Renderer.new

        renderer.render_partial(
          "_code_block", {
            code_block_html: code_block_html,
            code_text: escape_html_attribute(code_text),
            copy_icon: copy_icon
          }
        )
      end

      def escape_html_attribute(text)
        text.gsub('"', "&quot;")
          .gsub("'", "&#39;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
      end
    end
  end
end
