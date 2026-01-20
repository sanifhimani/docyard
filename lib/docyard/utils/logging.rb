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

      private

      def default_logger
        logger = Logger.new($stdout)
        logger.level = Logger::INFO
        logger.formatter = log_formatter
        logger
      end

      def log_formatter
        proc do |severity, _datetime, _progname, msg|
          case severity
          when "DEBUG"
            "[DEBUG] #{msg}\n"
          when "INFO"
            "#{msg}\n"
          else
            "[#{severity}] #{msg}\n"
          end
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
