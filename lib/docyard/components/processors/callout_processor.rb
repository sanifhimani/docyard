# frozen_string_literal: true

require_relative "../../rendering/icons"
require_relative "../../rendering/renderer"
require_relative "../base_processor"
require_relative "../support/markdown_code_block_helper"
require "kramdown"
require "kramdown-parser-gfm"

module Docyard
  module Components
    module Processors
      class CalloutProcessor < BaseProcessor
        include Support::MarkdownCodeBlockHelper

        self.priority = 10

        CALLOUT_TYPES = {
          "note" => { title: "Note", icon: "info", color: "note" },
          "tip" => { title: "Tip", icon: "lightbulb", color: "tip" },
          "important" => { title: "Important", icon: "warning-circle", color: "important" },
          "warning" => { title: "Warning", icon: "warning", color: "warning" },
          "danger" => { title: "Danger", icon: "siren", color: "danger" }
        }.freeze

        GITHUB_ALERT_TYPES = {
          "NOTE" => "note",
          "TIP" => "tip",
          "IMPORTANT" => "important",
          "WARNING" => "warning",
          "CAUTION" => "danger"
        }.freeze

        def preprocess(markdown)
          @code_block_ranges = find_code_block_ranges(markdown)
          process_container_syntax(markdown)
        end

        def postprocess(html)
          process_github_alerts(html)
        end

        private

        def process_container_syntax(markdown)
          markdown.gsub(/^:::[ \t]*(\w+)(?:[ \t]+([^\n]+?))?[ \t]*\n(.*?)^:::[ \t]*$/m) do
            match = Regexp.last_match
            next match[0] if inside_code_block?(match.begin(0), @code_block_ranges)

            process_callout_match(match[0], match[1], match[2], match[3])
          end
        end

        def process_callout_match(original_match, type_raw, custom_title, content_markdown)
          type = type_raw.downcase
          return original_match unless CALLOUT_TYPES.key?(type)

          config = CALLOUT_TYPES[type]
          title = determine_title(custom_title, config[:title])
          content_html = render_markdown_content(content_markdown.strip)

          wrap_in_nomarkdown(render_callout_html(type, title, content_html, config[:icon]))
        end

        def determine_title(custom_title, default_title)
          title = custom_title&.strip
          title.nil? || title.empty? ? default_title : title
        end

        def render_markdown_content(content_markdown)
          return "" if content_markdown.empty?

          Kramdown::Document.new(
            content_markdown,
            input: "GFM",
            hard_wrap: false,
            syntax_highlighter: "rouge"
          ).to_html
        end

        def wrap_in_nomarkdown(html)
          "{::nomarkdown}\n#{html}\n{:/nomarkdown}"
        end

        def process_github_alerts(html)
          github_alert_regex = %r{
            <blockquote>\s*
            <p>\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*
            (?:<br\s*/>)?\s*
            (.*?)</p>
            (.*?)
            </blockquote>
          }mx

          html.gsub(github_alert_regex) do
            process_github_alert_match(Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3))
          end
        end

        def process_github_alert_match(alert_type, first_para, rest_content)
          type = GITHUB_ALERT_TYPES[alert_type]
          config = CALLOUT_TYPES[type]
          content_html = combine_alert_content(first_para.strip, rest_content.strip)

          render_callout_html(type, config[:title], content_html, config[:icon])
        end

        def combine_alert_content(first_para, rest_content)
          return "<p>#{first_para}</p>" if rest_content.empty?

          "<p>#{first_para}</p>#{rest_content}"
        end

        def render_callout_html(type, title, content_html, icon_name)
          icon_svg = Icons.render(icon_name, "regular") || ""
          renderer = Renderer.new

          renderer.render_partial(
            "_callout", {
              type: type,
              title: title,
              content_html: content_html,
              icon_svg: icon_svg
            }
          )
        end
      end
    end
  end
end
