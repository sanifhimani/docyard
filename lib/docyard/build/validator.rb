# frozen_string_literal: true

module Docyard
  module Build
    class Validator
      attr_reader :config, :strict, :diagnostics

      def initialize(config, strict: false)
        @config = config
        @strict = strict
        @diagnostics = []
      end

      def valid?
        @diagnostics = collect_diagnostics
        errors.empty?
      end

      def errors
        diagnostics.select(&:error?)
      end

      def warnings
        diagnostics.select(&:warning?)
      end

      def print_errors(context: "Build")
        return if errors.empty?

        print_header
        puts "  #{UI.red("#{context} failed due to validation errors:")}"
        puts
        errors.each { |d| puts format_error_line(d) }
        puts
      end

      def print_warnings
        return if warnings.empty?

        puts
        puts "  #{UI.yellow("#{warnings.size} warning(s) found:")}"
        warnings.each { |d| puts "    #{UI.yellow('warn ')}  #{d.location.ljust(26)} #{d.message}" }
        puts
      end

      private

      def print_header
        puts
        puts "  #{UI.bold('Docyard')} v#{VERSION}"
        puts
      end

      def format_error_line(diagnostic)
        "    #{UI.red('error')}  #{diagnostic.location.ljust(26)} #{diagnostic.message}"
      end

      def collect_diagnostics
        strict ? collect_strict_diagnostics : collect_essential_diagnostics
      end

      def collect_essential_diagnostics
        require_relative "../doctor/config_checker"
        require_relative "../doctor/sidebar_checker"

        [
          Doctor::ConfigChecker.new(config).check,
          Doctor::SidebarChecker.new(docs_path).check
        ].flatten
      end

      def collect_strict_diagnostics
        require_relative "../doctor"

        file_scanner = Doctor::FileScanner.new(docs_path)
        scanner_diagnostics = file_scanner.scan

        [
          collect_essential_diagnostics,
          scanner_diagnostics,
          Doctor::OrphanChecker.new(docs_path, config).check
        ].flatten
      end

      def docs_path
        config.source
      end
    end
  end
end
