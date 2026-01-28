# frozen_string_literal: true

module Docyard
  module Utils
    class TextFormatter
      def self.titleize(string)
        return "Home" if string == "index"

        string.gsub(/[-_]/, " ")
          .split
          .map(&:capitalize)
          .join(" ")
      end
    end
  end
end
