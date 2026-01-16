# frozen_string_literal: true

require_relative "../../rendering/renderer"
require_relative "../base_processor"
require_relative "../support/markdown_code_block_helper"
require "kramdown"
require "kramdown-parser-gfm"

module Docyard
  module Components
    module Processors
      class StepsProcessor < BaseProcessor
        include Support::MarkdownCodeBlockHelper

        self.priority = 10

        STEPS_PATTERN = /^:::steps\s*\n(.*?)^:::\s*$/m
        STEP_HEADING_PATTERN = /^###\s+(.+)$/

        def preprocess(markdown)
          @code_block_ranges = find_code_block_ranges(markdown)

          markdown.gsub(STEPS_PATTERN) do
            match = Regexp.last_match
            next match[0] if inside_code_block?(match.begin(0), @code_block_ranges)

            content = match[1]
            steps = parse_steps(content)

            wrap_in_nomarkdown(render_steps_html(steps))
          end
        end

        private

        def parse_steps(content)
          steps = []
          current_step = nil

          content.lines.each do |line|
            if line.match(STEP_HEADING_PATTERN)
              steps << current_step if current_step
              current_step = { title: Regexp.last_match(1).strip, content: "" }
            elsif current_step
              current_step[:content] += line
            end
          end

          steps << current_step if current_step
          steps
        end

        def render_steps_html(steps)
          renderer = Renderer.new

          steps_html = steps.map.with_index(1) do |step, index|
            content_html = render_markdown_content(step[:content].strip)

            renderer.render_partial(
              "_step", {
                number: index,
                title: step[:title],
                content_html: content_html,
                is_last: index == steps.length
              }
            )
          end.join("\n")

          "<div class=\"docyard-steps\">\n#{steps_html}\n</div>"
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
      end
    end
  end
end
