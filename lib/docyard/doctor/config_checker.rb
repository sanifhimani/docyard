# frozen_string_literal: true

module Docyard
  class Doctor
    class ConfigChecker
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def check
        validator = Config::Validator.new(config.data, source_dir: config.source)
        validator.validate_all
        validator.issues
      end
    end
  end
end
