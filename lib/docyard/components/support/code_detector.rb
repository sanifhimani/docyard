# frozen_string_literal: true

require_relative "../../rendering/icons"

module Docyard
  module Components
    module Support
      class CodeDetector
        def self.detect(content)
          new(content).detect
        end

        def initialize(content)
          @content = content
        end

        def detect
          return nil unless code_only?

          language = extract_language
          return nil unless language

          { language: language }
        end

        private

        attr_reader :content

        def code_only?
          stripped = content.strip
          return false unless stripped.start_with?("```") && stripped.end_with?("```")

          parts = stripped.split("```")
          parts.length == 2 && parts[0].empty?
        end

        def extract_language
          parts = content.strip.split("```")
          return nil unless parts[1]

          lines = parts[1].split("\n", 2)
          lang_line = lines[0].strip
          return nil if lang_line.empty? || lang_line.include?(" ")

          lang_line.downcase
        end
      end
    end
  end
end
