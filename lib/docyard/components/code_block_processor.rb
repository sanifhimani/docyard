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
        highlights = @options[@block_index]&.fetch(:highlights, []) || []

        show_line_numbers = determine_line_numbers(block_option)
        start_line = extract_start_line(block_option)
        line_numbers = show_line_numbers ? generate_line_numbers(code_text, start_line) : []

        processed_html = highlights.any? ? wrap_highlighted_lines(original_html, highlights, start_line) : original_html

        render_code_block_with_copy(
          html: processed_html,
          text: code_text,
          show_line_numbers: show_line_numbers,
          line_numbers: line_numbers,
          highlights: highlights,
          start_line: start_line
        )
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

      def wrap_highlighted_lines(html, highlights, start_line)
        html.gsub(%r{<pre[^>]*><code[^>]*>(.*?)</code></pre>}m) do
          pre_match = Regexp.last_match(0)
          code_content = Regexp.last_match(1)

          lines = split_code_into_lines(code_content)
          wrapped_lines = wrap_lines_with_highlight_classes(lines, highlights, start_line)

          pre_match.sub(code_content, wrapped_lines.join)
        end
      end

      def wrap_lines_with_highlight_classes(lines, highlights, start_line)
        lines.each_with_index.map do |line, index|
          line_num = start_line + index
          highlighted = highlights.include?(line_num)
          class_attr = highlighted ? "docyard-code-line docyard-code-line--highlighted" : "docyard-code-line"
          %(<span class="#{class_attr}">#{line}</span>)
        end
      end

      def split_code_into_lines(code_content)
        parser = CodeLineParser.new(code_content)
        parser.parse
      end

      # Parses code content into lines while preserving HTML tags
      class CodeLineParser
        def initialize(code_content)
          @code_content = code_content
          @lines = []
          @current_line = ""
          @in_tag = false
          @tag_buffer = ""
        end

        def parse
          @code_content.each_char { |char| process_char(char) }
          finalize
        end

        private

        def process_char(char)
          case char
          when "<" then start_tag(char)
          when ">" then end_tag_if_applicable(char)
          when "\n" then handle_newline
          else handle_regular_char(char)
          end
        end

        def start_tag(char)
          @in_tag = true
          @tag_buffer = char
        end

        def end_tag_if_applicable(char)
          if @in_tag
            @in_tag = false
            @tag_buffer += char
            @current_line += @tag_buffer
            @tag_buffer = ""
          else
            @current_line += char
          end
        end

        def handle_newline
          @lines << "#{@current_line}\n"
          @current_line = ""
        end

        def handle_regular_char(char)
          if @in_tag
            @tag_buffer += char
          else
            @current_line += char
          end
        end

        def finalize
          @lines << @current_line unless @current_line.empty?
          @lines << "" if @lines.empty?
          @lines
        end
      end

      def extract_code_text(html)
        text = html.gsub(/<[^>]+>/, "")
        text = CGI.unescapeHTML(text)
        text.strip
      end

      def render_code_block_with_copy(block_data)
        copy_icon = Icons.render("copy", "regular") || ""
        renderer = Renderer.new

        renderer.render_partial(
          "_code_block", {
            code_block_html: block_data[:html],
            code_text: escape_html_attribute(block_data[:text]),
            copy_icon: copy_icon,
            show_line_numbers: block_data[:show_line_numbers],
            line_numbers: block_data[:line_numbers],
            highlights: block_data[:highlights],
            start_line: block_data[:start_line]
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
