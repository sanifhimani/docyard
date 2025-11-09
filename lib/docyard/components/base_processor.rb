# frozen_string_literal: true

module Docyard
  module Components
    class BaseProcessor
      class << self
        attr_accessor :priority

        def inherited(subclass)
          super
          Registry.register(subclass)
        end
      end

      def preprocess(content)
        content
      end

      def postprocess(html)
        html
      end
    end
  end
end
