# frozen_string_literal: true

require "json"
require_relative "../editor_launcher"

module Docyard
  class ErrorOverlay
    CATEGORY_LABELS = {
      CONFIG: "Configuration",
      SIDEBAR: "Sidebar",
      CONTENT: "Content",
      COMPONENT: "Component",
      LINK: "Links",
      IMAGE: "Images",
      SYNTAX: "Syntax",
      ORPHAN: "Orphan Pages"
    }.freeze

    GLOBAL_CATEGORIES = %i[CONFIG SIDEBAR ORPHAN].freeze

    class << self
      def render(diagnostics:, current_file:, sse_port:)
        return "" if diagnostics.empty?

        attrs = build_data_attributes(diagnostics, current_file, sse_port)
        render_overlay_html(attrs)
      end

      private

      def build_data_attributes(diagnostics, current_file, sse_port)
        global_count = diagnostics.count { |d| GLOBAL_CATEGORIES.include?(d.category) }
        page_count = diagnostics.length - global_count

        {
          diagnostics: escape_json(diagnostics),
          current_file: escape_html(current_file),
          error_count: diagnostics.count(&:error?),
          warning_count: diagnostics.count(&:warning?),
          global_count: global_count,
          page_count: page_count,
          sse_port: sse_port,
          editor_available: EditorLauncher.available?
        }
      end

      def render_overlay_html(attrs)
        <<~HTML
          <div id="docyard-error-overlay" class="docyard-error-overlay"
               data-diagnostics='#{attrs[:diagnostics]}'
               data-current-file="#{attrs[:current_file]}"
               data-error-count="#{attrs[:error_count]}"
               data-warning-count="#{attrs[:warning_count]}"
               data-global-count="#{attrs[:global_count]}"
               data-page-count="#{attrs[:page_count]}"
               data-sse-port="#{attrs[:sse_port]}"
               data-editor-available="#{attrs[:editor_available]}">
          </div>
          <link rel="stylesheet" href="/_docyard/error-overlay.css">
          <script src="/_docyard/error-overlay.js"></script>
        HTML
      end

      def escape_json(diagnostics)
        JSON.generate(diagnostics.map(&:to_h)).gsub("'", "&#39;")
      end

      def escape_html(str)
        str.to_s.gsub("&", "&amp;").gsub('"', "&quot;").gsub("<", "&lt;").gsub(">", "&gt;")
      end
    end
  end
end
