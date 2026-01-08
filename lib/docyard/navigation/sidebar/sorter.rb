# frozen_string_literal: true

module Docyard
  module Sidebar
    module Sorter
      module_function

      def sort_by_order(items)
        items.sort_by do |item|
          order = item[:order]
          title = item[:title]&.downcase || ""
          if order.nil?
            [1, title]
          else
            [0, order, title]
          end
        end
      end
    end
  end
end
