# frozen_string_literal: true

module Docyard
  class Config
    module HashUtils
      module_function

      def deep_merge(hash1, hash2)
        hash1.merge(hash2) do |_key, v1, v2|
          if v2.nil?
            v1
          elsif v1.is_a?(Hash) && v2.is_a?(Hash)
            deep_merge(v1, v2)
          else
            v2
          end
        end
      end

      def deep_dup(hash)
        hash.transform_values do |value|
          case value
          when Hash then deep_dup(value)
          when Array then value.map { |v| v.is_a?(Hash) ? deep_dup(v) : v }
          else value
          end
        end
      end
    end
  end
end
