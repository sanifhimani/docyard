# frozen_string_literal: true

module Docyard
  class Config
    module KeyValidator
      class << self
        def validate(hash, valid_keys, context:)
          return [] unless hash.is_a?(Hash)

          unknown = hash.keys.map(&:to_s) - valid_keys
          unknown.map { |key| build_error(key, valid_keys, context) }
        end

        private

        def build_error(key, valid_keys, context)
          suggestion = find_suggestion(key, valid_keys)
          msg = "unknown key '#{key}'"
          msg += ". Did you mean '#{suggestion}'?" if suggestion
          { context: context, message: msg }
        end

        def find_suggestion(key, valid_keys)
          checker = DidYouMean::SpellChecker.new(dictionary: valid_keys)
          checker.correct(key).first
        end
      end
    end
  end
end
