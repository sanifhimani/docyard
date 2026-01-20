# frozen_string_literal: true

require_relative "../../../rendering/icons"

module Docyard
  module Components
    module Support
      module CodeGroup
        class HtmlBuilder
          def initialize(blocks, group_id)
            @blocks = blocks
            @group_id = group_id
          end

          def build
            <<~HTML
              <div class="docyard-code-group" data-code-group="#{@group_id}">
                <div class="docyard-code-group__tabs-wrapper">
                  <div class="docyard-code-group__tabs-scroll-container">
                    <div role="tablist" aria-label="Code examples" class="docyard-code-group__tabs">
                      #{build_tabs}
                      <div class="docyard-code-group__indicator" aria-hidden="true"></div>
                    </div>
                  </div>
                  #{build_copy_button}
                </div>
                <div class="docyard-code-group__panels">
                  #{build_panels}
                </div>
              </div>
            HTML
          end

          private

          def build_tabs
            @blocks.each_with_index.map do |block, index|
              build_tab(block, index)
            end.join("\n")
          end

          def build_tab(block, index)
            selected = index.zero? ? "true" : "false"
            tabindex = index.zero? ? "0" : "-1"
            icon_html = render_icon(block[:lang])
            <<~HTML.strip
              <button
                role="tab"
                aria-selected="#{selected}"
                aria-controls="cg-panel-#{@group_id}-#{index}"
                id="cg-tab-#{@group_id}-#{index}"
                class="docyard-code-group__tab"
                tabindex="#{tabindex}"
                data-label="#{escape_html(block[:label])}"
              >#{icon_html}#{escape_html(block[:label])}</button>
            HTML
          end

          def render_icon(lang)
            return "" if lang.nil? || lang.empty?

            Icons.render_for_language(lang)
          end

          def build_copy_button
            copy_icon = Icons.render("copy", "regular") || ""
            <<~HTML.strip
              <button class="docyard-code-group__copy" aria-label="Copy code to clipboard">
                <span class="docyard-code-group__copy-icon">#{copy_icon}</span>
                <span class="docyard-code-group__copy-text">Copy</span>
              </button>
            HTML
          end

          def build_panels
            @blocks.each_with_index.map do |block, index|
              build_panel(block, index)
            end.join("\n")
          end

          def build_panel(block, index)
            hidden = index.zero? ? "false" : "true"
            code_text = escape_html_attribute(block[:code_text] || "")
            <<~HTML.strip
              <div
                role="tabpanel"
                id="cg-panel-#{@group_id}-#{index}"
                aria-labelledby="cg-tab-#{@group_id}-#{index}"
                aria-hidden="#{hidden}"
                class="docyard-code-group__panel"
                tabindex="0"
                data-code="#{code_text}"
              >#{block[:content]}</div>
            HTML
          end

          def escape_html(text)
            text.to_s
              .gsub("&", "&amp;")
              .gsub("<", "&lt;")
              .gsub(">", "&gt;")
              .gsub('"', "&quot;")
          end

          def escape_html_attribute(text)
            text.to_s
              .gsub("&", "&amp;")
              .gsub("<", "&lt;")
              .gsub(">", "&gt;")
              .gsub('"', "&quot;")
              .gsub("'", "&#39;")
              .gsub("\n", "&#10;")
          end
        end
      end
    end
  end
end
