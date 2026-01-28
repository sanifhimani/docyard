# frozen_string_literal: true

module Docyard
  class Config
    class Issue
      attr_reader :severity, :field, :message, :got, :expected, :fix

      def initialize(severity:, field:, message:, got: nil, expected: nil, fix: nil)
        @severity = severity
        @field = field
        @message = message
        @got = got
        @expected = expected
        @fix = fix
      end

      def error?
        severity == :error
      end

      def warning?
        severity == :warning
      end

      def fixable?
        fix.is_a?(Hash) && fix[:type]
      end

      def format_short
        suffix = fixable? ? " [fixable]" : ""
        "#{field.ljust(24)} #{message}#{suffix}"
      end

      def format_detailed
        lines = [field.to_s]
        lines << "  #{message}"
        lines << "  Got: #{format_got}" if got
        lines << "  Expected: #{expected}" if expected
        lines.join("\n")
      end

      private

      def format_got
        case got
        when String then got.length > 50 ? "#{got[0..47]}..." : got
        else got.inspect
        end
      end
    end
  end
end
