# frozen_string_literal: true

module Docyard
  module Components
    class TableWrapperProcessor < BaseProcessor
      self.priority = 100

      def postprocess(html)
        wrapped = html.gsub(/<table([^>]*)>/) do
          attributes = Regexp.last_match(1)
          "<div class=\"table-wrapper\"><table#{attributes}>"
        end

        wrapped.gsub("</table>", "</table></div>")
      end
    end
  end
end
