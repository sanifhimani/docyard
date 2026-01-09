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
        credits: true,
        social: []
      }
    end

    def config_branding_options
      site_options
        .merge(logo_options)
        .merge(search_options)
        .merge(credits_options)
        .merge(social_options)
    end

    def site_options
      {
        site_title: config.title || Constants::DEFAULT_SITE_TITLE,
        site_description: config.description || "",
        favicon: config.branding.favicon
      }
    end

    def logo_options
      branding = config.branding
      logo = branding.logo
      has_custom_logo = !logo.nil?
      {
        logo: logo || Constants::DEFAULT_LOGO_PATH,
        logo_dark: detect_dark_logo(logo) || Constants::DEFAULT_LOGO_DARK_PATH,
        has_custom_logo: has_custom_logo
      }
    end

    def detect_dark_logo(logo)
      return nil unless logo

      ext = File.extname(logo)
      base = File.basename(logo, ext)
      dark_filename = "#{base}-dark#{ext}"

      if File.absolute_path?(logo)
        dark_path = File.join(File.dirname(logo), dark_filename)
        File.exist?(dark_path) ? dark_path : logo
      else
        dark_path = File.join("docs/public", dark_filename)
        File.exist?(dark_path) ? dark_filename : logo
      end
    end

    def search_options
      {
        search_enabled: config.search.enabled != false,
        search_placeholder: config.search.placeholder || "Search..."
      }
    end

    def credits_options
      {
        credits: config.branding.credits != false
      }
    end

    def social_options
      socials = config.socials || {}
      {
        social: normalize_social_links(socials)
      }
    end

    def normalize_social_links(socials)
      return [] unless socials.is_a?(Hash) && socials.any?

      socials.map do |platform, url|
        next if platform == "custom"
        next unless url.is_a?(String) && !url.strip.empty?

        {
          platform: platform.to_s,
          url: url,
          icon: platform.to_s
        }
      end.compact
    end
  end
end
