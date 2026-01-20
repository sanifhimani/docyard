# frozen_string_literal: true

module Docyard
  class Config
    class Section
      def initialize(data)
        @data = data || {}
      end

      def method_missing(method, *args)
        return super unless args.empty?

        @data[method.to_s]
      end

      def respond_to_missing?(method, include_private = false)
        @data.key?(method.to_s) || super
      end
    end
  end
end
