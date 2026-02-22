# frozen_string_literal: true

module Docyard
  module Components
    module Support
      module CodeBlock
        module AnnotationListParser
          ORDERED_LIST_ITEM = /\A(\d+)\.\s+(.*)/
          CONTINUATION_LINE = /\A\s{2,}(\S.*)/
          BLANK_LINE = /\A\s*\z/
          LIST_START = /\A(\s*\n)*(\d+\.\s+)/m

          module_function

          def parse(text)
            state = { items: {}, current_num: nil, current_lines: [] }
            catch(:done) { text.each_line { |line| consume_line(state, line) } }
            finalize(state)
            state[:items]
          end

          def find_after_code_block(content, position)
            rest = content[position..]
            return nil unless rest

            preamble = rest.match(LIST_START)
            return nil unless preamble

            list_start = preamble.begin(2)
            list_text = rest[list_start..]
            parsed = parse_with_extent(list_text)
            return nil if parsed[:items].empty?

            { text: parsed[:consumed], end_position: position + list_start + parsed[:length], items: parsed[:items] }
          end

          def parse_with_extent(text)
            state = { items: {}, current_num: nil, current_lines: [] }
            consumed_length = 0

            catch(:done) do
              text.each_line do |line|
                consume_line(state, line)
                consumed_length += line.length
              end
            end

            finalize(state)
            { items: state[:items], consumed: text[0...consumed_length], length: consumed_length }
          end

          def consume_line(state, line)
            if (match = line.match(ORDERED_LIST_ITEM))
              start_new_item(state, match)
            elsif state[:current_num] && (cont = line.match(CONTINUATION_LINE))
              state[:current_lines] << cont[1].rstrip
            elsif state[:current_num] && line.match?(BLANK_LINE)
              state[:current_lines] << ""
            else
              finalize(state)
              throw :done
            end
          end

          def start_new_item(state, match)
            finalize(state)
            state[:current_num] = match[1].to_i
            state[:current_lines] = [match[2].rstrip]
          end

          def finalize(state)
            return unless state[:current_num]

            state[:items][state[:current_num]] = state[:current_lines].join("\n").strip
            state[:current_num] = nil
            state[:current_lines] = []
          end

          private_class_method :consume_line, :start_new_item, :finalize, :parse_with_extent
        end
      end
    end
  end
end
