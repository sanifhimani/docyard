# frozen_string_literal: true

require_relative "../../rendering/icons"
require_relative "../../rendering/renderer"
require_relative "../base_processor"
require_relative "../support/code_block/icon_detector"
require_relative "../support/code_block/line_wrapper"
require_relative "../support/code_block/line_number_resolver"
require_relative "../support/tabs/range_finder"

module Docyard
  module Components
    module Processors
      class CodeBlockProcessor < BaseProcessor
        include Support::CodeBlock::LineWrapper
        include Utils::HtmlHelpers

        self.priority = 20

        CodeBlockIconDetector = Support::CodeBlock::IconDetector
        LineNumbers = Support::CodeBlock::LineNumberResolver
        TabsRangeFinder = Support::Tabs::RangeFinder

        def postprocess(html)
          return html unless html.include?('<div class="highlight">')

          initialize_postprocess_state(html)
          process_all_highlight_blocks(html)
        end

        private

        def initialize_postprocess_state(html)
          @block_index = 0
          @options = context[:code_block_options] || []
          initialize_line_feature_state
          @tabs_ranges = TabsRangeFinder.find_ranges(html)
        end

        def initialize_line_feature_state
          @diff_lines = context[:code_block_diff_lines] || []
          @focus_lines = context[:code_block_focus_lines] || []
          @error_lines = context[:code_block_error_lines] || []
          @warning_lines = context[:code_block_warning_lines] || []
          @annotation_markers = context[:code_block_annotation_markers] || []
          @annotation_content = context[:code_block_annotation_content] || []
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
          processed_html = inject_scroll_spacer(processed_html) unless block_data[:title]

          render_code_block_with_copy(block_data.merge(html: processed_html))
        end

        def inject_scroll_spacer(html)
          spacer = '<span class="docyard-code-block__scroll-spacer" aria-hidden="true"></span>'
          html.sub("\n", "#{spacer}\n")
        end

        def extract_block_data(inner_html)
          opts = current_block_options
          code_text = extract_code_text(inner_html)
          start_line = LineNumbers.start_line(opts[:option])
          show_line_numbers = LineNumbers.enabled?(opts[:option])
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
            text: code_text, highlights: opts[:highlights],
            show_line_numbers: show_line_numbers, start_line: start_line,
            line_numbers: show_line_numbers ? LineNumbers.generate_numbers(code_text, start_line) : [],
            title: title_data[:title], icon: title_data[:icon], icon_source: title_data[:icon_source]
          }.merge(current_line_features)
        end

        def current_line_features
          {
            diff_lines: @diff_lines[@block_index] || {},
            focus_lines: @focus_lines[@block_index] || {},
            error_lines: @error_lines[@block_index] || {},
            warning_lines: @warning_lines[@block_index] || {},
            annotation_markers: @annotation_markers[@block_index] || {},
            annotation_content: @annotation_content[@block_index] || {}
          }
        end

        def process_html_for_highlighting(original_html, block_data)
          needs_wrapping = block_data[:highlights].any? || block_data[:diff_lines].any? ||
                           block_data[:focus_lines].any? || block_data[:error_lines].any? ||
                           block_data[:warning_lines].any? || block_data[:annotation_markers].any?
          return original_html unless needs_wrapping

          wrap_code_block(original_html, block_data)
        end

        def inside_tabs?(position)
          @tabs_ranges.any? { |range| range.cover?(position) }
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
          base_locals(block_data).merge(line_feature_locals(block_data)).merge(title_locals(block_data))
        end

        def base_locals(block_data)
          { code_block_html: block_data[:html], code_text: escape_html_attribute(block_data[:text]),
            copy_icon: Icons.render("copy", "regular") || "", show_line_numbers: block_data[:show_line_numbers],
            line_numbers: block_data[:line_numbers], start_line: block_data[:start_line] }
        end

        def line_feature_locals(block_data)
          { highlights: block_data[:highlights], diff_lines: block_data[:diff_lines],
            focus_lines: block_data[:focus_lines], error_lines: block_data[:error_lines],
            warning_lines: block_data[:warning_lines], annotation_markers: block_data[:annotation_markers],
            annotation_content: block_data[:annotation_content] }
        end

        def title_locals(block_data)
          { title: block_data[:title], icon: block_data[:icon], icon_source: block_data[:icon_source] }
        end
      end
    end
  end
end
