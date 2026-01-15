# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      class AbbreviationProcessor < BaseProcessor
        DEFINITION_PATTERN = /^\*\[([^\]]+)\]:\s*(.+)$/
        self.priority = 5

        def preprocess(content)
          abbreviations = extract_abbreviations(content)
          return content if abbreviations.empty?

          content = remove_definitions(content)
          apply_abbreviations(content, abbreviations)
        end

        private

        def extract_abbreviations(content)
          abbreviations = {}
          content.scan(DEFINITION_PATTERN) do |term, definition|
            abbreviations[term] = definition.strip
          end
          abbreviations
        end

        def remove_definitions(content)
          content.gsub(/^[ \t]*\*\[([^\]]+)\]:\s*.+$\n?/, "")
        end

        def apply_abbreviations(content, abbreviations)
          abbreviations.each do |term, definition|
            pattern = build_term_pattern(term)
            content = content.gsub(pattern) do |match|
              build_abbr_tag(match, definition)
            end
          end
          content
        end

        def build_term_pattern(term)
          escaped = Regexp.escape(term)
          /(?<![<\w])#{escaped}(?![>\w])/
        end

        def build_abbr_tag(term, definition)
          escaped_definition = escape_html(definition)
          %(<abbr class="docyard-abbr" data-definition="#{escaped_definition}">#{term}</abbr>)
        end

        def escape_html(text)
          text.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub('"', "&quot;")
        end
      end
    end
  end
end
