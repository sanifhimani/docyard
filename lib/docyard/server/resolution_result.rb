# frozen_string_literal: true

module Docyard
  class ResolutionResult
    attr_reader :file_path, :status

    def self.found(file_path)
      new(file_path: file_path, status: :found)
    end

    def self.not_found
      new(file_path: nil, status: :not_found)
    end

    def initialize(file_path:, status:)
      @file_path = file_path
      @status = status
      freeze
    end

    def found?
      status == :found
    end

    def not_found?
      status == :not_found
    end
  end
end
