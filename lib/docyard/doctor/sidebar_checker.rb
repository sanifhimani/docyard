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
        convert_to_issues(loader.key_errors)
      end

      private

      def convert_to_issues(key_errors)
        key_errors.map do |error|
          Config::Issue.new(
            severity: :error,
            field: "_sidebar.yml: #{error[:context]}",
            message: error[:message]
          )
        end
      end
    end
  end
end
