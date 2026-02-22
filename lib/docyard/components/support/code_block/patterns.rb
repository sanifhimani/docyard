# frozen_string_literal: true

module Docyard
  module Components
    module Support
      module CodeBlock
        module Patterns
          DIFF_MARKER_PATTERN = %r{
            (?:
              //\s*\[!code\s*([+-]{2})\]              |
              \#\s*\[!code\s*([+-]{2})\]              |
              /\*\s*\[!code\s*([+-]{2})\]\s*\*/       |
              --\s*\[!code\s*([+-]{2})\]              |
              <!--\s*\[!code\s*([+-]{2})\]\s*-->      |
              ;\s*\[!code\s*([+-]{2})\]
            )[^\S\n]*
          }x

          FOCUS_MARKER_PATTERN = %r{
            (?:
              //\s*\[!code\s+focus\]              |
              \#\s*\[!code\s+focus\]              |
              /\*\s*\[!code\s+focus\]\s*\*/       |
              --\s*\[!code\s+focus\]              |
              <!--\s*\[!code\s+focus\]\s*-->      |
              ;\s*\[!code\s+focus\]
            )[^\S\n]*
          }x

          ERROR_MARKER_PATTERN = %r{
            (?:
              //\s*\[!code\s+error\]              |
              \#\s*\[!code\s+error\]              |
              /\*\s*\[!code\s+error\]\s*\*/       |
              --\s*\[!code\s+error\]              |
              <!--\s*\[!code\s+error\]\s*-->      |
              ;\s*\[!code\s+error\]
            )[^\S\n]*
          }x

          WARNING_MARKER_PATTERN = %r{
            (?:
              //\s*\[!code\s+warning\]              |
              \#\s*\[!code\s+warning\]              |
              /\*\s*\[!code\s+warning\]\s*\*/       |
              --\s*\[!code\s+warning\]              |
              <!--\s*\[!code\s+warning\]\s*-->      |
              ;\s*\[!code\s+warning\]
            )[^\S\n]*
          }x

          ANNOTATION_MARKER_PATTERN = %r{
            (?:
              //\s*\((\d+)\)\s*$              |
              \#\s*\((\d+)\)\s*$              |
              /\*\s*\((\d+)\)\s*\*/\s*$       |
              --\s*\((\d+)\)\s*$              |
              <!--\s*\((\d+)\)\s*-->\s*$      |
              ;\s*\((\d+)\)\s*$
            )
          }x
        end
      end
    end
  end
end
