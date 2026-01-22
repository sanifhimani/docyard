# frozen_string_literal: true

module Docyard
  class Config
    module Validators
      module Navigation
        private

        def validate_navigation_section
          cta = @config.dig("navigation", "cta")
          return if cta.nil?
          return add_array_error("navigation.cta") unless cta.is_a?(Array)

          validate_cta_max_count(cta)
          validate_cta_items(cta)
        end

        def validate_cta_items(cta)
          cta.each_with_index do |item, idx|
            validate_string(item["text"], "navigation.cta[#{idx}].text")
            validate_string(item["href"], "navigation.cta[#{idx}].href")
            validate_cta_variant(item["variant"], idx) if item.key?("variant")
            validate_boolean(item["external"], "navigation.cta[#{idx}].external") if item.key?("external")
          end
        end

        def validate_cta_max_count(cta)
          return if cta.length <= 2

          add_error(field: "navigation.cta", error: "maximum 2 CTAs allowed",
                    got: "#{cta.length} items", fix: "Remove extra CTA items to have at most 2")
        end

        def validate_cta_variant(variant, idx)
          return if variant.nil? || %w[primary secondary].include?(variant)

          add_error(field: "navigation.cta[#{idx}].variant", error: "must be 'primary' or 'secondary'",
                    got: variant, fix: "Change to 'primary' or 'secondary'")
        end
      end
    end
  end
end
