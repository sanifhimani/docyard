# frozen_string_literal: true

module Docyard
  class Config
    module Schema
      BRANDING_SCHEMA = {
        type: :hash,
        keys: {
          logo: { type: :file_or_url },
          favicon: { type: :file_or_url },
          credits: { type: :boolean },
          copyright: { type: :string },
          color: { type: :color }
        }
      }.freeze

      BUILD_SCHEMA = {
        type: :hash,
        keys: {
          output: { type: :string, format: :no_slashes },
          base: { type: :string, format: :starts_with_slash },
          strict: { type: :boolean }
        }
      }.freeze

      SEARCH_SCHEMA = {
        type: :hash,
        keys: {
          enabled: { type: :boolean },
          placeholder: { type: :string },
          exclude: { type: :array, items: { type: :string } }
        }
      }.freeze

      ANNOUNCEMENT_SCHEMA = {
        type: :hash,
        keys: {
          text: { type: :string },
          link: { type: :string },
          dismissible: { type: :boolean },
          button: {
            type: :hash,
            keys: { text: { type: :string }, link: { type: :string } }
          }
        }
      }.freeze

      REPO_SCHEMA = {
        type: :hash,
        keys: {
          url: { type: :url },
          branch: { type: :string },
          edit_path: { type: :string },
          edit_link: { type: :boolean },
          last_updated: { type: :boolean }
        }
      }.freeze

      ANALYTICS_SCHEMA = {
        type: :hash,
        keys: {
          google: { type: :string },
          plausible: { type: :string },
          fathom: { type: :string },
          script: { type: :string }
        }
      }.freeze

      FEEDBACK_SCHEMA = {
        type: :hash,
        keys: {
          enabled: { type: :boolean },
          question: { type: :string }
        }
      }.freeze
    end
  end
end
