# frozen_string_literal: true

require_relative "../base_processor"
require_relative "../support/markdown_code_block_helper"

module Docyard
  module Components
    module Processors
      class VariablesProcessor < BaseProcessor
        include Support::MarkdownCodeBlockHelper

        VARIABLE_PATTERN = /\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}/
        VARS_SUFFIX_PATTERN = /^(`{3,}|~{3,})(\S+)-vars(.*)/

        self.priority = 1

        def preprocess(content)
          variables = context.dig(:config, "variables") || {}
          return content if variables.empty?

          segments = split_by_code_blocks(content)
          segments.map { |segment| process_segment(segment, variables) }.join
        end

        private

        def process_segment(segment, variables)
          return substitute_variables(segment[:content], variables) if segment[:type] == :text

          match = segment[:content].match(VARS_SUFFIX_PATTERN)
          return segment[:content] unless match

          stripped = segment[:content].sub("#{match[2]}-vars", match[2])
          substitute_variables(stripped, variables)
        end

        def substitute_variables(content, variables)
          content.gsub(VARIABLE_PATTERN) do |original|
            key = Regexp.last_match(1)
            value = resolve_variable(key, variables)
            value.nil? ? original : value.to_s
          end
        end

        def resolve_variable(key, variables)
          keys = key.split(".")
          keys.reduce(variables) do |current, k|
            return nil unless current.is_a?(Hash)

            current[k]
          end
        end
      end
    end
  end
end
