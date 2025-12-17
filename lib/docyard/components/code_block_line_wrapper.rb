# frozen_string_literal: true

require_relative "code_line_parser"

module Docyard
  module Components
    module CodeBlockLineWrapper
      module_function

      def wrap_code_block(html, highlights, diff_lines, focus_lines, start_line)
        html.gsub(%r{<pre[^>]*><code[^>]*>(.*?)</code></pre>}m) do
          pre_match = Regexp.last_match(0)
          code_content = Regexp.last_match(1)
          lines = CodeLineParser.new(code_content).parse
          wrapped_lines = wrap_lines_with_classes(lines, highlights, diff_lines, focus_lines, start_line)
          pre_match.sub(code_content, wrapped_lines.join)
        end
      end

      def wrap_lines_with_classes(lines, highlights, diff_lines, focus_lines, start_line)
        lines.each_with_index.map do |line, index|
          source_line = index + 1
          display_line = start_line + index
          classes = build_line_classes(source_line, display_line, highlights, diff_lines, focus_lines)
          %(<span class="#{classes}">#{line}</span>)
        end
      end

      def build_line_classes(source_line, display_line, highlights, diff_lines, focus_lines)
        classes = ["docyard-code-line"]
        classes << "docyard-code-line--highlighted" if highlights.include?(display_line)
        classes << "docyard-code-line--diff-add" if diff_lines[source_line] == :addition
        classes << "docyard-code-line--diff-remove" if diff_lines[source_line] == :deletion
        classes << "docyard-code-line--focus" if focus_lines[source_line]
        classes.join(" ")
      end
    end
  end
end
