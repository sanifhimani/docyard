# frozen_string_literal: true

module Docyard
  module Components
    class Registry
      @processors = []

      class << self
        def register(processor_class)
          @processors << processor_class
          @processors.sort_by! { |p| p.priority || 100 }
        end

        def run_preprocessors(content)
          @processors.reduce(content) do |processed_content, processor_class|
            processor_class.new.preprocess(processed_content)
          end
        end

        def run_postprocessors(html)
          @processors.reduce(html) do |processed_html, processor_class|
            processor_class.new.postprocess(processed_html)
          end
        end

        def reset!
          @processors = []
        end

        attr_reader :processors
      end
    end
  end
end
