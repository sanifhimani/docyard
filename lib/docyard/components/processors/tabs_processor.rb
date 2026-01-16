# frozen_string_literal: true

require_relative "../../rendering/renderer"
require_relative "../base_processor"
require_relative "../support/markdown_code_block_helper"
require_relative "../support/tabs/parser"
require "securerandom"

module Docyard
  module Components
    module Processors
      class TabsProcessor < BaseProcessor
        include Support::MarkdownCodeBlockHelper

        self.priority = 15

        TabsParser = Support::Tabs::Parser

        def preprocess(content)
          return content unless content.include?(":::tabs")

          @code_block_ranges = find_code_block_ranges(content)

          content.gsub(/^:::[ \t]*tabs[ \t]*\n(.*?)^:::[ \t]*$/m) do
            match = Regexp.last_match
            next match[0] if inside_code_block?(match.begin(0), @code_block_ranges)

            process_tabs_block(match[1])
          end
        end

        private

        def process_tabs_block(tabs_content)
          tabs = TabsParser.parse(tabs_content)
          return "" if tabs.empty?

          wrap_in_nomarkdown(render_tabs(tabs))
        end

        def render_tabs(tabs)
          Renderer.new.render_partial(
            "_tabs", {
              tabs: tabs,
              group_id: SecureRandom.hex(4)
            }
          )
        end

        def wrap_in_nomarkdown(html)
          "{::nomarkdown}\n#{html}\n{:/nomarkdown}"
        end
      end
    end
  end
end
