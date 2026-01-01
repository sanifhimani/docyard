# frozen_string_literal: true

require_relative "../../../rendering/language_mapping"

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

            icon, icon_source = auto_detect_icon(language)
            { title: title, icon: icon, icon_source: icon_source }
          end

          def auto_detect_icon(language)
            return [nil, nil] if language.nil?

            if LanguageMapping.terminal_language?(language)
              %w[terminal-window phosphor]
            elsif (ext = LanguageMapping.extension_for(language))
              [ext, "file-extension"]
            else
              %w[file phosphor]
            end
          end
        end
      end
    end
  end
end
