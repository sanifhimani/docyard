# frozen_string_literal: true

require "logger"

module Docyard
  module Logging
    class << self
      attr_writer :logger

      def logger
        @logger ||= default_logger
      end

      def level=(level)
        logger.level = Logger.const_get(level.to_s.upcase)
      end

      def start_buffering
        @buffered_warnings = []
        @buffering = true
      end

      def stop_buffering
        @buffering = false
        warnings = @buffered_warnings || []
        @buffered_warnings = []
        warnings
      end

      def buffering?
        @buffering == true
      end

      def buffer_warning(message)
        @buffered_warnings ||= []
        @buffered_warnings << message
      end

      def flush_warnings
        warnings = stop_buffering
        warnings.each { |msg| logger.warn(msg) }
      end

      private

      def default_logger
        logger = Logger.new($stdout)
        logger.level = Logger::INFO
        logger.formatter = log_formatter
        logger
      end

      def log_formatter
        proc do |severity, _datetime, _progname, msg|
          if severity == "WARN" && buffering?
            buffer_warning(msg)
            nil
          else
            format_message(severity, msg)
          end
        end
      end

      def format_message(severity, msg)
        case severity
        when "DEBUG"
          "#{UI.dim('[DEBUG]')} #{msg}\n"
        when "INFO"
          "#{msg}\n"
        when "WARN"
          "#{UI.warning('[WARN]')} #{msg}\n"
        when "ERROR"
          "#{UI.error('[ERROR]')} #{msg}\n"
        else
          "[#{severity}] #{msg}\n"
        end
      end
    end
  end

  def self.logger
    Logging.logger
  end

  def self.log_level=(level)
    Logging.level = level
  end
end
