# frozen_string_literal: true

module Docyard
  class Config
    module TypeValidators
      def validate_string(value, definition, field)
        unless value.is_a?(String)
          add_type_issue(field, "string", value)
          return
        end

        validate_format(value, definition[:format], field) if definition[:format]
      end

      def validate_format(value, format, field)
        case format
        when :no_slashes
          return unless value.include?("/") || value.include?("\\")

          add_diagnostic(:error, field, "cannot contain slashes", got: value,
                                                                  expected: "simple directory name like 'dist'")
        when :starts_with_slash
          return if value.start_with?("/")

          add_diagnostic(:error, field, "must start with /", got: value,
                                                             fix: { type: :replace, value: "/#{value}" })
        end
      end

      def validate_boolean(value, field)
        return if [true, false].include?(value)

        fix = nil
        if %w[true false yes no].include?(value.to_s.downcase)
          fix = { type: :replace, value: %w[true yes].include?(value.to_s.downcase) }
        end

        add_diagnostic(:error, field, "must be true or false", got: value.inspect, fix: fix)
      end

      def validate_url(value, field)
        return if value.nil?
        return add_type_issue(field, "URL string", value) unless value.is_a?(String)
        return if value.match?(%r{\Ahttps?://})

        add_diagnostic(:warning, field, "should be a valid URL starting with http:// or https://", got: value)
      end

      def validate_enum(value, definition, field)
        valid_values = definition[:values]
        return if valid_values.include?(value)

        suggestion = find_suggestion(value.to_s, valid_values)
        fix = suggestion ? { type: :replace, value: suggestion } : nil

        add_diagnostic(:error, field, "invalid value", got: value,
                                                       expected: valid_values.join(", "), fix: fix)
      end

      def validate_hash(value, definition, field)
        return add_type_issue(field, "hash/object", value) unless value.is_a?(Hash)
        return unless definition[:keys]

        validate_structure(value, definition[:keys], field)
      end

      def validate_array(value, definition, field)
        return add_type_issue(field, "array", value) unless value.is_a?(Array)

        validate_array_max_items(value, definition, field)
        validate_array_items(value, definition, field)
      end

      def validate_array_max_items(value, definition, field)
        return unless definition[:max_items] && value.size > definition[:max_items]

        add_diagnostic(:error, field, "has too many items", got: "#{value.size} items",
                                                            expected: "maximum #{definition[:max_items]} items")
      end

      def validate_array_items(value, definition, field)
        return unless definition[:items]

        value.each_with_index do |item, index|
          validate_field(item, definition[:items], "#{field}[#{index}]")
        end
      end

      def validate_file_or_url(value, field)
        return if value.nil?
        return add_type_issue(field, "file path or URL", value) unless value.is_a?(String)
        return if value.match?(%r{\Ahttps?://})
        return if File.exist?(value)

        public_dir = File.join(@source_dir, "public")
        file_path = File.join(public_dir, value)
        return if File.exist?(file_path)

        add_diagnostic(:error, field, "file not found", got: value,
                                                        expected: "file in #{public_dir}/ or a URL")
      end

      def validate_hex_color(value, field)
        return if value.nil?
        return add_type_issue(field, "hex color string", value) unless value.is_a?(String)
        return if value.match?(/\A#[0-9a-fA-F]{3}\z/) || value.match?(/\A#[0-9a-fA-F]{6}\z/)

        add_diagnostic(:error, field, "invalid hex color format", got: value,
                                                                  expected: "#RGB or #RRGGBB format (e.g., #3b82f6)")
      end

      def validate_color(value, field)
        return if value.nil?
        return if value.is_a?(String)
        return if value.is_a?(Hash)

        add_type_issue(field, "color string or {light:, dark:} hash", value)
      end
    end
  end
end
