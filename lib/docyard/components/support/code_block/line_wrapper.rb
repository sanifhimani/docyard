# frozen_string_literal: true

require_relative "line_parser"

module Docyard
  module Components
    module Support
      module CodeBlock
        module LineWrapper
          module_function

          def wrap_code_block(html, block_data)
            html.gsub(%r{<pre[^>]*><code[^>]*>(.*?)</code></pre>}m) do
              pre_match = Regexp.last_match(0)
              code_content = Regexp.last_match(1)
              lines = LineParser.new(code_content).parse
              wrapped_lines = wrap_lines_with_classes(lines, block_data)
              pre_match.sub(code_content, wrapped_lines.join)
            end
          end

          def wrap_lines_with_classes(lines, block_data)
            lines.each_with_index.map do |line, index|
              source_line = index + 1
              display_line = block_data[:start_line] + index
              classes = build_line_classes(source_line, display_line, block_data)
              %(<span class="#{classes}">#{line}</span>)
            end
          end

          DIFF_CLASSES = { addition: "docyard-code-line--diff-add", deletion: "docyard-code-line--diff-remove" }.freeze

          def build_line_classes(source_line, display_line, block_data)
            (["docyard-code-line"] + feature_classes(source_line, display_line, block_data)).join(" ")
          end

          def feature_classes(source_line, display_line, block_data)
            [
              ("docyard-code-line--highlighted" if block_data[:highlights].include?(display_line)),
              DIFF_CLASSES[block_data[:diff_lines][source_line]],
              ("docyard-code-line--focus" if block_data[:focus_lines][source_line]),
              ("docyard-code-line--error" if block_data[:error_lines][source_line]),
              ("docyard-code-line--warning" if block_data[:warning_lines][source_line])
            ].compact
          end
        end
      end
    end
  end
end
