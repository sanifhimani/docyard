# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"
require_relative "../base_processor"
require_relative "../support/code_block/patterns"
require_relative "../support/code_block/annotation_list_parser"

module Docyard
  module Components
    module Processors
      class CodeBlockAnnotationPreprocessor < BaseProcessor
        include Support::CodeBlock::Patterns

        self.priority = 8

        CODE_BLOCK_REGEX = /^```(\w*).*?\n(.*?)^```/m
        TABS_BLOCK_REGEX = /^:::tabs[ \t]*\n.*?^:::[ \t]*$/m
        CODE_GROUP_REGEX = /^:::code-group[ \t]*\n.*?^:::[ \t]*$/m

        ListParser = Support::CodeBlock::AnnotationListParser

        def preprocess(content)
          initialize_state
          @skip_ranges = find_skip_ranges(content)
          process_content(content)
        end

        private

        def initialize_state
          context[:code_block_annotation_markers] ||= []
          context[:code_block_annotation_content] ||= []
          @block_index = 0
        end

        def process_content(content)
          result = +""
          last_end = 0

          content.scan(CODE_BLOCK_REGEX) do
            match = Regexp.last_match
            next if match.begin(0) < last_end

            result << content[last_end...match.begin(0)]
            processed, new_end = process_match(match, content)
            result << processed
            last_end = new_end
          end

          result << content[last_end..]
        end

        def process_match(match, content)
          if inside_skip_range?(match.begin(0))
            [match[0], match.end(0)]
          else
            process_annotated_block(match, content)
          end
        end

        def process_annotated_block(match, content)
          markers = extract_annotation_markers(match[2])
          code_end = match.end(0)

          if markers.any?
            process_with_list(match, content, markers, code_end)
          else
            store_empty_markers
            @block_index += 1
            [match[0], code_end]
          end
        end

        def process_with_list(match, content, markers, code_end)
          list_result = ListParser.find_after_code_block(content, code_end)

          if list_result
            store_markers_and_content(markers, list_result[:items])
            cleaned_code = strip_annotation_markers(match[2])
            @block_index += 1
            ["#{match[0].sub(match[2], cleaned_code)}\n", list_result[:end_position]]
          else
            store_empty_markers
            @block_index += 1
            [match[0], code_end]
          end
        end

        def store_markers_and_content(markers, list_items)
          context[:code_block_annotation_markers][@block_index] = markers
          context[:code_block_annotation_content][@block_index] = render_annotation_content(list_items)
        end

        def store_empty_markers
          context[:code_block_annotation_markers][@block_index] = {}
          context[:code_block_annotation_content][@block_index] = {}
        end

        def extract_annotation_markers(code_content)
          markers = {}
          code_content.lines.each_with_index do |line, index|
            next unless (match = line.match(ANNOTATION_MARKER_PATTERN))

            num = match.captures.compact.first.to_i
            markers[index + 1] = num
          end
          markers
        end

        def strip_annotation_markers(code_content)
          code_content.lines.map { |line| strip_single_marker(line) }.join
        end

        def strip_single_marker(line)
          return line unless line.match?(ANNOTATION_MARKER_PATTERN)

          stripped = line.sub(ANNOTATION_MARKER_PATTERN, "")
          stripped.end_with?("\n") ? stripped : "#{stripped}\n"
        end

        def render_annotation_content(list_items)
          list_items.transform_values { |markdown_text| render_markdown(markdown_text) }
        end

        def render_markdown(text)
          Kramdown::Document.new(text, input: "GFM", hard_wrap: false).to_html.strip
        end

        def inside_skip_range?(position)
          @skip_ranges.any? { |range| range.cover?(position) }
        end

        def find_skip_ranges(content)
          find_ranges(content, TABS_BLOCK_REGEX) + find_ranges(content, CODE_GROUP_REGEX)
        end

        def find_ranges(content, pattern)
          ranges = []
          content.scan(pattern) do
            match = Regexp.last_match
            ranges << (match.begin(0)...match.end(0))
          end
          ranges
        end
      end
    end
  end
end
