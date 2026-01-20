# frozen_string_literal: true

require_relative "../../../rendering/icons"

module Docyard
  module Components
    module Support
      module CodeBlock
        module IconDetector
          MANUAL_ICON_PATTERN = /^:([a-z0-9-]+):\s*(.+)$/i

          module_function

          def detect(title, language)
            return { title: nil, icon: nil, icon_source: nil } if title.nil?

            if (match = title.match(MANUAL_ICON_PATTERN))
              return {
                title: match[2].strip,
                icon: match[1],
                icon_source: "phosphor"
              }
            end

            { title: title, icon: language, icon_source: "language" }
          end

          def render_icon(language)
            return "" if language.nil? || language.to_s.empty?

            Icons.render_for_language(language)
          end
        end
      end
    end
  end
end
