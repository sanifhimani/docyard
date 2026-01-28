# frozen_string_literal: true

require_relative "schema"
require_relative "issue"
require_relative "type_validators"

module Docyard
  class Config
    class Validator
      include TypeValidators

      VALIDATORS_WITH_DEFINITION = %i[string enum hash array].freeze

      attr_reader :issues

      def initialize(data, source_dir: "docs")
        @data = data
        @source_dir = source_dir
        @issues = []
      end

      def validate!
        validate_all
        return if errors.empty?

        raise ConfigError, format_errors_for_exception
      end

      def validate_all
        @issues = []
        validate_unknown_keys(@data, Schema::DEFINITION, "docyard.yml")
        validate_structure(@data, Schema::DEFINITION, "")
        validate_cross_field_rules
        @issues
      end

      def errors
        @issues.select(&:error?)
      end

      def warnings
        @issues.select(&:warning?)
      end

      def fixable_issues
        @issues.select(&:fixable?)
      end

      private

      def validate_unknown_keys(data, schema, context, allow_extra: false)
        return unless data.is_a?(Hash)

        check_unknown_keys(data, schema, context, allow_extra)
        validate_nested_hash_keys(data, schema, context)
      end

      def check_unknown_keys(data, schema, context, allow_extra)
        return if allow_extra

        valid_keys = schema.keys.map(&:to_s)
        data.each_key do |key|
          next if valid_keys.include?(key.to_s)

          add_unknown_key_issue(context, key, valid_keys)
        end
      end

      def validate_nested_hash_keys(data, schema, context)
        schema.each do |key, definition|
          next unless nested_hash_definition?(definition)
          next unless data[key.to_s].is_a?(Hash)

          nested_context = build_context(context, key)
          nested_allow_extra = definition[:allow_extra_keys] || false
          validate_unknown_keys(data[key.to_s], definition[:keys], nested_context, allow_extra: nested_allow_extra)
        end
      end

      def nested_hash_definition?(definition)
        definition.is_a?(Hash) && definition[:type] == :hash && definition[:keys]
      end

      def build_context(prefix, key)
        prefix.empty? || prefix == "docyard.yml" ? key.to_s : "#{prefix}.#{key}"
      end

      def validate_structure(data, schema, prefix)
        schema.each do |key, definition|
          field = build_context(prefix, key)
          value = data.is_a?(Hash) ? data[key.to_s] : nil
          validate_field(value, definition, field)
        end
      end

      def validate_field(value, definition, field)
        if value.nil? && definition[:required]
          add_issue(:error, field, "is required")
          return
        end

        check_recommended(value, definition, field)
        return if value.nil?

        validate_type(value, definition, field)
      end

      def check_recommended(value, definition, field)
        return unless definition[:recommended] && (value.nil? || value.to_s.strip.empty?)

        add_issue(:warning, field, "is recommended for better SEO")
      end

      def validate_type(value, definition, field)
        return if value.nil?

        type = definition[:type]
        validator_method = :"validate_#{type}"
        return unless respond_to?(validator_method, true)

        if VALIDATORS_WITH_DEFINITION.include?(type)
          send(validator_method, value, definition, field)
        else
          send(validator_method, value, field)
        end
      end

      def validate_cross_field_rules
        validate_feedback_requires_analytics
      end

      def validate_feedback_requires_analytics
        feedback = @data["feedback"]
        return unless feedback.is_a?(Hash) && feedback["enabled"] == true

        analytics = @data["analytics"]
        return if analytics.is_a?(Hash) && analytics.values.any?

        add_issue(:error, "feedback.enabled", "requires analytics to be configured",
                  expected: "configure google, plausible, fathom, or script in analytics section")
      end

      def add_issue(severity, field, message, got: nil, expected: nil, fix: nil)
        @issues << Issue.new(
          severity: severity,
          field: field,
          message: message,
          got: got,
          expected: expected,
          fix: fix
        )
      end

      def add_type_issue(field, expected_type, value)
        add_issue(:error, field, "must be a #{expected_type}", got: value.class.name)
      end

      def add_unknown_key_issue(context, key, valid_keys)
        field = context == "docyard.yml" ? key.to_s : "#{context}.#{key}"
        suggestion = find_suggestion(key.to_s, valid_keys.map(&:to_s))
        message = "unknown key"
        message += ", did you mean '#{suggestion}'?" if suggestion
        fix = suggestion ? { type: :rename, from: key.to_s, to: suggestion } : nil

        add_issue(:error, field, message, fix: fix)
      end

      def find_suggestion(key, valid_keys)
        checker = DidYouMean::SpellChecker.new(dictionary: valid_keys)
        checker.correct(key).first
      end

      def format_errors_for_exception
        lines = ["Config errors in docyard.yml:", ""]
        errors.each do |issue|
          lines << "  #{issue.field}"
          lines << "    #{issue.message}"
          lines << "    Got: #{issue.got}" if issue.got
          lines << "    Expected: #{issue.expected}" if issue.expected
          lines << ""
        end
        lines.join("\n")
      end
    end
  end
end
