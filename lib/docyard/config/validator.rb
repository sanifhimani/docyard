# frozen_string_literal: true

require_relative "schema"
require_relative "type_validators"

module Docyard
  class Config
    class Validator
      include TypeValidators

      VALIDATORS_WITH_DEFINITION = %i[string enum hash array].freeze

      attr_reader :diagnostics

      def initialize(data, source_dir: "docs")
        @data = data
        @source_dir = source_dir
        @diagnostics = []
      end

      def validate_all
        @diagnostics = []
        validate_unknown_keys(@data, Schema::DEFINITION, "docyard.yml")
        validate_structure(@data, Schema::DEFINITION, "")
        validate_cross_field_rules
        @diagnostics
      end

      def errors
        @diagnostics.select(&:error?)
      end

      def warnings
        @diagnostics.select(&:warning?)
      end

      def fixable_issues
        @diagnostics.select(&:fixable?)
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
          add_diagnostic(:error, field, "is required")
          return
        end

        return if value.nil?

        validate_type(value, definition, field)
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

        add_diagnostic(:error, "feedback.enabled", "requires analytics to be configured",
                       expected: "configure google, plausible, fathom, or script in analytics section")
      end

      def add_diagnostic(severity, field, message, got: nil, expected: nil, fix: nil)
        @diagnostics << Diagnostic.new(
          severity: severity,
          category: :CONFIG,
          code: "CONFIG_VALIDATION",
          file: "docyard.yml",
          field: field,
          message: message,
          details: build_details(got, expected),
          fix: fix
        )
      end

      def build_details(got, expected)
        details = {}
        details[:got] = got if got
        details[:expected] = expected if expected
        details.empty? ? nil : details
      end

      def add_type_issue(field, expected_type, value)
        add_diagnostic(:error, field, "must be a #{expected_type}", got: value.class.name)
      end

      def add_unknown_key_issue(context, key, valid_keys)
        field = context == "docyard.yml" ? key.to_s : "#{context}.#{key}"
        suggestion = find_suggestion(key.to_s, valid_keys.map(&:to_s))
        message = "unknown key"
        message += ", did you mean '#{suggestion}'?" if suggestion
        fix = suggestion ? { type: :rename, from: key.to_s, to: suggestion } : nil

        add_diagnostic(:error, field, message, fix: fix)
      end

      def find_suggestion(key, valid_keys)
        checker = DidYouMean::SpellChecker.new(dictionary: valid_keys)
        checker.correct(key).first
      end
    end
  end
end
