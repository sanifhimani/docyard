# frozen_string_literal: true

require_relative "../icons"
require_relative "../language_mapping"
require_relative "../renderer"
require_relative "base_processor"
require_relative "code_block_icon_detector"
require_relative "code_line_parser"
require_relative "tabs_range_finder"

module Docyard
  module Components
    class CodeBlockProcessor < BaseProcessor
      self.priority = 20

      def postprocess(html)
        return html unless html.include?('<div class="highlight">')

        initialize_postprocess_state(html)
        process_all_highlight_blocks(html)
      end

      private

      def initialize_postprocess_state(html)
        @block_index = 0
        @options = context[:code_block_options] || []
        @diff_lines = context[:code_block_diff_lines] || []
        @global_line_numbers = context.dig(:config, "markdown", "lineNumbers") || false
        @tabs_ranges = TabsRangeFinder.find_ranges(html)
      end

      def process_all_highlight_blocks(html)
        result = +""
        last_end = 0

        html.scan(%r{<div class="highlight">(.*?)</div>}m) do
          match = Regexp.last_match
          result << html[last_end...match.begin(0)]
          result << process_highlight_match(match)
          last_end = match.end(0)
        end

        result << html[last_end..]
      end

      def process_highlight_match(match)
        if inside_tabs?(match.begin(0))
          match[0]
        else
          processed = process_code_block(match[0], match[1])
          @block_index += 1
          processed
        end
      end

      def process_code_block(original_html, inner_html)
        block_data = extract_block_data(inner_html)
        processed_html = process_html_for_highlighting(original_html, block_data)

        render_code_block_with_copy(block_data.merge(html: processed_html))
      end

      def extract_block_data(inner_html)
        opts = current_block_options
        code_text = extract_code_text(inner_html)
        start_line = extract_start_line(opts[:option])
        show_line_numbers = determine_line_numbers(opts[:option])
        title_data = CodeBlockIconDetector.detect(opts[:title], opts[:lang])

        build_block_data(code_text, opts, show_line_numbers, start_line, title_data)
      end

      def current_block_options
        block_opts = @options[@block_index] || {}
        {
          option: block_opts[:option],
          title: block_opts[:title],
          lang: block_opts[:lang],
          highlights: block_opts[:highlights] || []
        }
      end

      def build_block_data(code_text, opts, show_line_numbers, start_line, title_data)
        {
          text: code_text,
          highlights: opts[:highlights],
          diff_lines: @diff_lines[@block_index] || {},
          show_line_numbers: show_line_numbers,
          line_numbers: show_line_numbers ? generate_line_numbers(code_text, start_line) : [],
          start_line: start_line,
          title: title_data[:title],
          icon: title_data[:icon],
          icon_source: title_data[:icon_source]
        }
      end

      def process_html_for_highlighting(original_html, block_data)
        needs_wrapping = block_data[:highlights].any? || block_data[:diff_lines].any?
        return original_html unless needs_wrapping

        wrap_lines(original_html, block_data[:highlights], block_data[:diff_lines], block_data[:start_line])
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

      def inside_tabs?(position)
        @tabs_ranges.any? { |range| range.cover?(position) }
      end

      def wrap_lines(html, highlights, diff_lines, start_line)
        html.gsub(%r{<pre[^>]*><code[^>]*>(.*?)</code></pre>}m) do
          pre_match = Regexp.last_match(0)
          code_content = Regexp.last_match(1)

          lines = split_code_into_lines(code_content)
          wrapped_lines = wrap_lines_with_classes(lines, highlights, diff_lines, start_line)

          pre_match.sub(code_content, wrapped_lines.join)
        end
      end

      def wrap_lines_with_classes(lines, highlights, diff_lines, start_line)
        lines.each_with_index.map do |line, index|
          line_num = start_line + index
          classes = build_line_classes(line_num, highlights, diff_lines)
          %(<span class="#{classes}">#{line}</span>)
        end
      end

      def build_line_classes(line_num, highlights, diff_lines)
        classes = ["docyard-code-line"]
        classes << "docyard-code-line--highlighted" if highlights.include?(line_num)
        classes << "docyard-code-line--diff-add" if diff_lines[line_num] == :addition
        classes << "docyard-code-line--diff-remove" if diff_lines[line_num] == :deletion
        classes.join(" ")
      end

      def split_code_into_lines(code_content)
        parser = CodeLineParser.new(code_content)
        parser.parse
      end

      def extract_code_text(html)
        text = html.gsub(/<[^>]+>/, "")
        text = CGI.unescapeHTML(text)
        text.strip
      end

      def render_code_block_with_copy(block_data)
        Renderer.new.render_partial("_code_block", template_locals(block_data))
      end

      def template_locals(block_data)
        {
          code_block_html: block_data[:html],
          code_text: escape_html_attribute(block_data[:text]),
          copy_icon: Icons.render("copy", "regular") || "",
          show_line_numbers: block_data[:show_line_numbers],
          line_numbers: block_data[:line_numbers],
          highlights: block_data[:highlights],
          diff_lines: block_data[:diff_lines],
          start_line: block_data[:start_line],
          title: block_data[:title],
          icon: block_data[:icon],
          icon_source: block_data[:icon_source]
        }
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
