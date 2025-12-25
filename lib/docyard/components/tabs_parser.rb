# frozen_string_literal: true

require_relative "code_block_feature_extractor"
require_relative "code_block_icon_detector"
require_relative "code_block_line_wrapper"
require_relative "icon_detector"
require_relative "../icons"
require_relative "../renderer"
require "kramdown"
require "kramdown-parser-gfm"
require "cgi"

module Docyard
  module Components
    class TabsParser
      def self.parse(content)
        new(content).parse
      end

      def initialize(content)
        @content = content
      end

      def parse
        sections.filter_map { |section| parse_section(section) }
      end

      private

      attr_reader :content

      def sections
        content.split(/^==[ \t]+/)
      end

      def parse_section(section)
        return nil if section.strip.empty?

        tab_name, tab_content = extract_tab_parts(section)
        return nil if tab_name.nil? || tab_name.empty?

        build_tab_data(tab_name, tab_content)
      end

      def extract_tab_parts(section)
        parts = section.split("\n", 2)
        [parts[0]&.strip, parts[1]&.strip || ""]
      end

      def build_tab_data(tab_name, tab_content)
        icon_data = IconDetector.detect(tab_name, tab_content)

        extracted = CodeBlockFeatureExtractor.process_markdown(tab_content)
        rendered_content = render_markdown(extracted[:cleaned_markdown])
        enhanced_content = enhance_code_blocks(rendered_content, extracted[:blocks])

        {
          name: icon_data[:name],
          content: enhanced_content,
          icon: icon_data[:icon],
          icon_source: icon_data[:icon_source]
        }
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

        processed_html = if needs_line_wrapping?(block_data)
                           wrap_code_block_lines(original_html, block_data)
                         else
                           original_html
                         end

        Renderer.new.render_partial("_code_block", build_full_locals(processed_html, code_text, block_data))
      end

      def needs_line_wrapping?(block_data)
        %i[highlights diff_lines focus_lines error_lines warning_lines].any? do |key|
          block_data[key]&.any?
        end
      end

      def wrap_code_block_lines(html, block_data)
        wrapper_data = {
          highlights: block_data[:highlights] || [],
          diff_lines: block_data[:diff_lines] || {},
          focus_lines: block_data[:focus_lines] || {},
          error_lines: block_data[:error_lines] || {},
          warning_lines: block_data[:warning_lines] || {},
          start_line: extract_start_line(block_data[:option])
        }
        CodeBlockLineWrapper.wrap_code_block(html, wrapper_data)
      end

      def build_full_locals(processed_html, code_text, block_data)
        title_data = CodeBlockIconDetector.detect(block_data[:title], block_data[:lang])
        show_line_numbers = line_numbers_enabled?(block_data[:option])
        start_line = extract_start_line(block_data[:option])

        base_locals(processed_html, code_text, show_line_numbers, start_line)
          .merge(feature_locals(block_data))
          .merge(title_locals(title_data))
      end

      def base_locals(processed_html, code_text, show_line_numbers, start_line)
        {
          code_block_html: processed_html,
          code_text: escape_html_attribute(code_text),
          copy_icon: Icons.render("copy", "regular") || "",
          show_line_numbers: show_line_numbers,
          line_numbers: show_line_numbers ? generate_line_numbers(code_text, start_line) : [],
          start_line: start_line
        }
      end

      def feature_locals(block_data)
        {
          highlights: block_data[:highlights] || [],
          diff_lines: block_data[:diff_lines] || {},
          focus_lines: block_data[:focus_lines] || {},
          error_lines: block_data[:error_lines] || {},
          warning_lines: block_data[:warning_lines] || {}
        }
      end

      def title_locals(title_data)
        {
          title: title_data[:title],
          icon: title_data[:icon],
          icon_source: title_data[:icon_source]
        }
      end

      def line_numbers_enabled?(block_option)
        return false if block_option == ":no-line-numbers"
        return true if block_option&.start_with?(":line-numbers")

        false
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

      def escape_html_attribute(text)
        text.gsub('"', "&quot;")
          .gsub("'", "&#39;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
      end
    end
  end
end
