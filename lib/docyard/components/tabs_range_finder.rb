# frozen_string_literal: true

module Docyard
  module Components
    module TabsRangeFinder
      module_function

      def find_ranges(html)
        ranges = []
        start_pattern = '<div class="docyard-tabs"'

        pos = 0
        while (start_pos = html.index(start_pattern, pos))
          end_pos = find_matching_close_div(html, start_pos)
          ranges << (start_pos...end_pos) if end_pos
          pos = end_pos || (start_pos + 1)
        end
        ranges
      end

      def find_matching_close_div(html, start_pos)
        depth = 0
        pos = start_pos

        while pos < html.length
          if html[pos, 4] == "<div"
            depth += 1
            pos += 4
          elsif html[pos, 6] == "</div>"
            depth -= 1
            return pos + 6 if depth.zero?

            pos += 6
          else
            pos += 1
          end
        end
        nil
      end
    end
  end
end
