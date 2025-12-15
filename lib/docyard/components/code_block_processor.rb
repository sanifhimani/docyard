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

        @block_index = 0
        @options = context[:code_block_options] || []
        @global_line_numbers = context.dig(:config, "markdown", "lineNumbers") || false

        html.gsub(%r{<div class="highlight">(.*?)</div>}m) do
          result = process_code_block(Regexp.last_match(0), Regexp.last_match(1))
          @block_index += 1
          result
        end
      end

      private

      def process_code_block(original_html, inner_html)
        code_text = extract_code_text(inner_html)
        block_option = @options[@block_index]&.fetch(:option, nil)

        show_line_numbers = determine_line_numbers(block_option)
        start_line = extract_start_line(block_option)
        line_numbers = show_line_numbers ? generate_line_numbers(code_text, start_line) : []

        render_code_block_with_copy(original_html, code_text, show_line_numbers, line_numbers)
      end

      def determine_line_numbers(block_option)
        return false if block_option == ":no-line-numbers"
        return true if block_option&.start_with?(":line-numbers")

        @global_line_numbers
      end

      def extract_start_line(block_option)
        return 1 unless block_option&.include?("=")

        block_option.split("=").last.to_i
      end

      def generate_line_numbers(code_text, start_line)
        line_count = code_text.lines.count
        line_count = 1 if line_count.zero?
        (start_line...(start_line + line_count)).to_a
      end

      def extract_code_text(html)
        text = html.gsub(/<[^>]+>/, "")
        text = CGI.unescapeHTML(text)
        text.strip
      end

      def render_code_block_with_copy(code_block_html, code_text, show_line_numbers, line_numbers)
        copy_icon = Icons.render("copy", "regular") || ""
        renderer = Renderer.new

        renderer.render_partial(
          "_code_block", {
            code_block_html: code_block_html,
            code_text: escape_html_attribute(code_text),
            copy_icon: copy_icon,
            show_line_numbers: show_line_numbers,
            line_numbers: line_numbers
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
