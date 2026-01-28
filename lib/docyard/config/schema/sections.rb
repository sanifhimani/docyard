# frozen_string_literal: true

require_relative "simple_sections"

module Docyard
  class Config
    module Schema
      SOCIALS_SCHEMA = {
        type: :hash,
        allow_extra_keys: true,
        keys: {
          github: { type: :url },
          twitter: { type: :url },
          discord: { type: :url },
          slack: { type: :url },
          linkedin: { type: :url },
          youtube: { type: :url },
          bluesky: { type: :url },
          custom: {
            type: :array,
            items: {
              type: :hash,
              keys: { icon: { type: :string }, href: { type: :url } }
            }
          }
        }
      }.freeze

      TABS_SCHEMA = {
        type: :array,
        items: {
          type: :hash,
          keys: {
            text: { type: :string },
            href: { type: :string },
            icon: { type: :string },
            external: { type: :boolean }
          }
        }
      }.freeze

      NAVIGATION_SCHEMA = {
        type: :hash,
        keys: {
          breadcrumbs: { type: :boolean },
          cta: {
            type: :array,
            max_items: 2,
            items: {
              type: :hash,
              keys: {
                text: { type: :string },
                href: { type: :string },
                variant: { type: :enum, values: CTA_VARIANTS },
                external: { type: :boolean }
              }
            }
          }
        }
      }.freeze
    end
  end
end
