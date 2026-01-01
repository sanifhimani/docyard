# frozen_string_literal: true

require_relative "../code_detector"

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

            {
              name: tab_name,
              icon: detected[:icon],
              icon_source: detected[:source]
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
