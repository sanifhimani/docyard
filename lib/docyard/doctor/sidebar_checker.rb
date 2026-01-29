# frozen_string_literal: true

module Docyard
  class Doctor
    class SidebarChecker
      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
      end

      def check
        loader = Sidebar::LocalConfigLoader.new(docs_path, validate: false)
        loader.load
        convert_to_diagnostics(loader.key_errors)
      end

      private

      def convert_to_diagnostics(key_errors)
        key_errors.map do |error|
          Diagnostic.new(
            severity: :error,
            category: :SIDEBAR,
            code: "SIDEBAR_VALIDATION",
            field: "_sidebar.yml: #{error[:context]}",
            message: error[:message]
          )
        end
      end
    end
  end
end
