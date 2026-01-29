# frozen_string_literal: true

module Docyard
  class Diagnostic
    CATEGORIES = %i[CONFIG SIDEBAR CONTENT COMPONENT SYNTAX LINK IMAGE ORPHAN].freeze
    SEVERITIES = %i[error warning].freeze

    attr_reader :severity, :category, :code, :message, :file, :line, :field, :details, :fix

    def initialize(severity:, category:, code:, message:, file: nil, line: nil, field: nil, details: nil, fix: nil)
      validate_severity!(severity)
      validate_category!(category)

      @severity = severity.to_sym
      @category = category.to_sym
      @code = code.to_s
      @message = message
      @file = file
      @line = line
      @field = field
      @details = details
      @fix = fix

      freeze
    end

    def error?
      severity == :error
    end

    def warning?
      severity == :warning
    end

    def fixable?
      fix.is_a?(Hash) && !fix[:type].nil?
    end

    def location
      return field if field
      return "#{file}:#{line}" if file && line
      return file if file

      nil
    end

    def format_line
      loc = location&.ljust(26) || (" " * 26)
      prefix = error? ? "error" : "warn "
      suffix = fixable? ? " [fixable]" : ""
      "    #{prefix}   #{loc} #{message}#{suffix}"
    end

    def to_h
      {
        severity: severity,
        category: category,
        code: code,
        message: message,
        file: file,
        line: line,
        field: field,
        details: details,
        fix: fix
      }.compact
    end

    private

    def validate_severity!(severity)
      return if SEVERITIES.include?(severity.to_sym)

      raise ArgumentError, "Invalid severity: #{severity}. Must be one of: #{SEVERITIES.join(', ')}"
    end

    def validate_category!(category)
      return if CATEGORIES.include?(category.to_sym)

      raise ArgumentError, "Invalid category: #{category}. Must be one of: #{CATEGORIES.join(', ')}"
    end
  end
end
