# frozen_string_literal: true

module Docyard
  class BrandingResolver
    def initialize(config)
      @config = config
    end

    def resolve
      return default_branding unless config

      default_branding.merge(config_branding_options)
    end

    private

    attr_reader :config

    def default_branding
      {
        site_title: Constants::DEFAULT_SITE_TITLE,
        site_description: "",
        logo: Constants::DEFAULT_LOGO_PATH,
        logo_dark: Constants::DEFAULT_LOGO_DARK_PATH,
        favicon: nil,
        display_logo: true,
        display_title: true,
        credits: true,
        social: {}
      }
    end

    def config_branding_options
      site_options
        .merge(logo_options)
        .merge(search_options)
        .merge(appearance_options)
        .merge(credits_options)
        .merge(social_options)
    end

    def site_options
      {
        site_title: config.site.title || Constants::DEFAULT_SITE_TITLE,
        site_description: config.site.description || "",
        favicon: config.branding.favicon
      }
    end

    def logo_options
      branding = config.branding
      {
        logo: resolve_logo(branding.logo, branding.logo_dark),
        logo_dark: resolve_logo_dark(branding.logo, branding.logo_dark)
      }
    end

    def search_options
      {
        search_enabled: config.search.enabled != false,
        search_placeholder: config.search.placeholder || "Search documentation..."
      }
    end

    def appearance_options
      appearance = config.branding.appearance || {}
      {
        display_logo: appearance["logo"] != false,
        display_title: appearance["title"] != false
      }
    end

    def credits_options
      {
        credits: config.branding.credits != false
      }
    end

    def social_options
      social = config.branding.social || {}
      {
        social: normalize_social_links(social)
      }
    end

    def normalize_social_links(social)
      return [] unless social.is_a?(Hash) && social.any?

      social.map do |platform, url|
        next unless url.is_a?(String) && !url.strip.empty?

        {
          platform: platform.to_s,
          url: url,
          icon: platform.to_s
        }
      end.compact
    end

    def resolve_logo(logo, logo_dark)
      logo || logo_dark || Constants::DEFAULT_LOGO_PATH
    end

    def resolve_logo_dark(logo, logo_dark)
      logo_dark || logo || Constants::DEFAULT_LOGO_DARK_PATH
    end
  end
end
