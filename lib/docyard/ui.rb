# frozen_string_literal: true

module Docyard
  module UI
    CODES = {
      red: 31,
      green: 32,
      yellow: 33,
      cyan: 36,
      bold: 1,
      dim: 2
    }.freeze

    class << self
      attr_writer :enabled

      def enabled?
        return @enabled unless @enabled.nil?

        @enabled = determine_color_support
      end

      def reset!
        @enabled = nil
      end

      def red(text)
        wrap(text, CODES[:red])
      end

      def green(text)
        wrap(text, CODES[:green])
      end

      def yellow(text)
        wrap(text, CODES[:yellow])
      end

      def cyan(text)
        wrap(text, CODES[:cyan])
      end

      def bold(text)
        wrap(text, CODES[:bold])
      end

      def dim(text)
        wrap(text, CODES[:dim])
      end

      def success(text)
        wrap(text, CODES[:green], CODES[:bold])
      end

      def error(text)
        wrap(text, CODES[:red], CODES[:bold])
      end

      def warning(text)
        wrap(text, CODES[:yellow])
      end

      private

      def wrap(text, *codes)
        return text.to_s unless enabled?

        prefix = codes.map { |c| "\e[#{c}m" }.join
        "#{prefix}#{text}\e[0m"
      end

      def determine_color_support # rubocop:disable Naming/PredicateMethod
        return false if ENV.key?("NO_COLOR")
        return false unless $stdout.tty?

        true
      end
    end
  end
end
