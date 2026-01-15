# frozen_string_literal: true

require_relative "../base_processor"
require_relative "../support/code_block/feature_extractor"
require_relative "../support/code_block/line_wrapper"
require_relative "../support/code_group/html_builder"
require_relative "../../rendering/icons"
require_relative "../../rendering/renderer"
require "securerandom"
require "kramdown"
require "kramdown-parser-gfm"
require "cgi"

module Docyard
  module Components
    module Processors
      class CodeGroupProcessor < BaseProcessor
        include Utils::HtmlHelpers

        self.priority = 12

        CODE_GROUP_PATTERN = /^:::[ \t]*code-group[ \t]*\n(.*?)^:::[ \t]*$/m
        CODE_BLOCK_PATTERN = /```(\w*)\s*\[([^\]]+)\]([^\n]*)\n(.*?)```/m

        CodeBlockFeatureExtractor = Support::CodeBlock::FeatureExtractor
        CodeBlockLineWrapper = Support::CodeBlock::LineWrapper
        CodeGroupHtmlBuilder = Support::CodeGroup::HtmlBuilder

        def preprocess(content)
          return content unless content.include?(":::code-group")

          content.gsub(CODE_GROUP_PATTERN) do
            process_code_group(::Regexp.last_match(1))
          end
        end

        private

        def process_code_group(inner_content)
          blocks = extract_code_blocks(inner_content)
          return "" if blocks.empty?

          group_id = SecureRandom.hex(4)
          html = CodeGroupHtmlBuilder.new(blocks, group_id).build
          wrap_in_nomarkdown(html)
        end

        def extract_code_blocks(content)
          blocks = []
          content.scan(CODE_BLOCK_PATTERN) do
            blocks << build_block_data(::Regexp.last_match)
          end
          blocks
        end

        def build_block_data(match)
          lang = match[1] || ""
          label = match[2]
          options = match[3].strip
          code = match[4]

          code_with_newline = code.end_with?("\n") ? code : "#{code}\n"
          markdown = "```#{lang}#{format_options(options)}\n#{code_with_newline}```"
          extracted = CodeBlockFeatureExtractor.process_markdown(markdown)
          rendered = render_and_enhance(extracted)

          { label: label, lang: lang, content: rendered, code_text: code.strip }
        end

        def format_options(options)
          return "" if options.empty?
          return options if options.start_with?(":")

          " #{options}"
        end

        def render_and_enhance(extracted)
          html = render_markdown(extracted[:cleaned_markdown])
          enhance_code_blocks(html, extracted[:blocks])
        end

        def render_markdown(markdown_content)
          return "" if markdown_content.empty?

          Kramdown::Document.new(
            markdown_content,
            input: "GFM",
            hard_wrap: false,
            syntax_highlighter: "rouge"
          ).to_html
        end

        def enhance_code_blocks(html, blocks)
          return html unless html.include?('<div class="highlight">')

          block_index = 0
          html.gsub(%r{<div class="highlight">(.*?)</div>}m) do
            block_data = blocks[block_index] || {}
            block_index += 1
            render_enhanced_code_block(Regexp.last_match, block_data)
          end
        end

        def render_enhanced_code_block(match, block_data)
          original_html = match[0]
          inner_html = match[1]
          code_text = extract_code_text(inner_html)

          processed_html = process_html_if_needed(original_html, block_data)
          Renderer.new.render_partial("_code_block", build_locals(processed_html, code_text, block_data))
        end

        def process_html_if_needed(original_html, block_data)
          return original_html unless needs_line_wrapping?(block_data)

          CodeBlockLineWrapper.wrap_code_block(original_html, wrapper_data(block_data))
        end

        def needs_line_wrapping?(block_data)
          %i[highlights diff_lines focus_lines error_lines warning_lines].any? do |key|
            block_data[key]&.any?
          end
        end

        def wrapper_data(block_data)
          {
            highlights: block_data[:highlights] || [],
            diff_lines: block_data[:diff_lines] || {},
            focus_lines: block_data[:focus_lines] || {},
            error_lines: block_data[:error_lines] || {},
            warning_lines: block_data[:warning_lines] || {},
            start_line: extract_start_line(block_data[:option])
          }
        end

        def build_locals(processed_html, code_text, block_data)
          base_locals(processed_html, code_text, block_data).merge(feature_locals(block_data)).merge(title_locals)
        end

        def base_locals(processed_html, code_text, block_data)
          show_ln = line_numbers_enabled?(block_data[:option])
          start = extract_start_line(block_data[:option])

          {
            code_block_html: processed_html, code_text: escape_html_attribute(code_text),
            copy_icon: Icons.render("copy", "regular") || "", show_line_numbers: show_ln,
            line_numbers: show_ln ? generate_line_numbers(code_text, start) : [], start_line: start
          }
        end

        def feature_locals(block_data)
          {
            highlights: block_data[:highlights] || [], diff_lines: block_data[:diff_lines] || {},
            focus_lines: block_data[:focus_lines] || {}, error_lines: block_data[:error_lines] || {},
            warning_lines: block_data[:warning_lines] || {}
          }
        end

        def title_locals
          { title: nil, icon: nil, icon_source: nil }
        end

        def line_numbers_enabled?(option)
          return false if option == ":no-line-numbers"
          return true if option&.start_with?(":line-numbers")

          false
        end

        def extract_start_line(option)
          return 1 unless option&.include?("=")

          option.split("=").last.to_i
        end

        def generate_line_numbers(code_text, start_line)
          count = [code_text.lines.count, 1].max
          (start_line...(start_line + count)).to_a
        end

        def extract_code_text(html)
          CGI.unescapeHTML(html.gsub(/<[^>]+>/, "")).strip
        end

        def wrap_in_nomarkdown(html)
          "{::nomarkdown}\n#{html}\n{:/nomarkdown}"
        end
      end
    end
  end
end
