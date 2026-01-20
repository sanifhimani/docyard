# frozen_string_literal: true

require_relative "../code_detector"
require_relative "../../../rendering/icons"

module Docyard
  module Components
    module Support
      module Tabs
        class IconDetector
          MANUAL_ICON_PATTERN = /^:([a-z0-9-]+):\s*(.+)$/i
          CodeDetector = Support::CodeDetector

          def self.detect(tab_name, tab_content)
            new(tab_name, tab_content).detect
          end

          def initialize(tab_name, tab_content)
            @tab_name = tab_name
            @tab_content = tab_content
          end

          def detect
            manual_icon || auto_detected_icon || no_icon
          end

          private

          attr_reader :tab_name, :tab_content

          def manual_icon
            return nil unless tab_name.match(MANUAL_ICON_PATTERN)

            {
              name: Regexp.last_match(2).strip,
              icon: Regexp.last_match(1),
              icon_source: "phosphor"
            }
          end

          def auto_detected_icon
            detected = CodeDetector.detect(tab_content)
            return nil unless detected

            language = detected[:language]
            return nil unless Icons.devicon?(language)

            {
              name: tab_name,
              icon: language,
              icon_source: "language"
            }
          end

          def no_icon
            {
              name: tab_name,
              icon: nil,
              icon_source: nil
            }
          end
        end
      end
    end
  end
end
