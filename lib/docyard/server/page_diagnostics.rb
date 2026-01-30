# frozen_string_literal: true

require_relative "../doctor/content_checker"
require_relative "../doctor/component_checker"
require_relative "../doctor/link_checker"
require_relative "../doctor/image_checker"

module Docyard
  class PageDiagnostics
    def initialize(docs_path)
      @docs_path = docs_path
      @content_checker = Doctor::ContentChecker.new(docs_path)
      @component_checker = Doctor::ComponentChecker.new(docs_path)
      @link_checker = Doctor::LinkChecker.new(docs_path)
      @image_checker = Doctor::ImageChecker.new(docs_path)
    end

    def check(content, file_path)
      [
        @content_checker.check_file(content, file_path),
        @component_checker.check_file(content, file_path),
        @link_checker.check_file(content, file_path),
        @image_checker.check_file(content, file_path)
      ].flatten
    end
  end
end
