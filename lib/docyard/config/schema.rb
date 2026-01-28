# frozen_string_literal: true

module Docyard
  class Config
    module Schema
      SIDEBAR_MODES = %w[config auto distributed].freeze
      CTA_VARIANTS = %w[primary secondary].freeze
      SIDEBAR_ITEM_KEYS = %w[text icon badge badge_type items collapsed index group collapsible].freeze
      SIDEBAR_EXTERNAL_LINK_KEYS = %w[link text icon target].freeze

      class << self
        def top_level_keys
          DEFINITION.keys.map(&:to_s)
        end

        def section_keys(section)
          section_def = DEFINITION[section.to_sym]
          return [] unless section_def&.dig(:keys)

          section_def[:keys].keys.map(&:to_s)
        end

        def validate_keys(hash, valid_keys, context:)
          return [] unless hash.is_a?(Hash)

          unknown = hash.keys.map(&:to_s) - valid_keys
          unknown.map { |key| build_key_error(key, valid_keys, context) }
        end

        def build_key_error(key, valid_keys, context)
          suggestion = find_key_suggestion(key, valid_keys)
          msg = "unknown key '#{key}'"
          msg += ". Did you mean '#{suggestion}'?" if suggestion
          { context: context, message: msg }
        end

        def find_key_suggestion(key, valid_keys)
          checker = DidYouMean::SpellChecker.new(dictionary: valid_keys)
          checker.correct(key).first
        end
      end
    end
  end
end

require_relative "schema/definition"
