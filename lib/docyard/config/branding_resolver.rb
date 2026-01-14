# frozen_string_literal: true

module Docyard
  class BrandingResolver
    def initialize(config)
      @config = config
    end

    SOCIAL_ICON_MAP = {
      "x" => "x-logo", "twitter" => "x-logo", "discord" => "discord-logo",
      "linkedin" => "linkedin-logo", "youtube" => "youtube-logo", "instagram" => "instagram-logo",
      "facebook" => "facebook-logo", "tiktok" => "tiktok-logo", "twitch" => "twitch-logo",
      "reddit" => "reddit-logo", "mastodon" => "mastodon-logo", "threads" => "threads-logo",
      "pinterest" => "pinterest-logo", "medium" => "medium-logo", "slack" => "slack-logo",
      "gitlab" => "gitlab-logo"
    }.freeze

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
        .merge(navigation_options)
        .merge(tabs_options)
    end

    def site_options
      {
        site_title: config.title || Constants::DEFAULT_SITE_TITLE,
        site_description: config.description || "",
        favicon: config.branding.favicon || auto_detect_favicon
      }
    end

    def logo_options
      branding = config.branding
      logo = branding.logo || auto_detect_logo
      has_custom_logo = !logo.nil?
      {
        logo: logo || Constants::DEFAULT_LOGO_PATH,
        logo_dark: detect_dark_logo(logo) || Constants::DEFAULT_LOGO_DARK_PATH,
        has_custom_logo: has_custom_logo
      }
    end

    def auto_detect_logo
      detect_public_file("logo", %w[svg png])
    end

    def auto_detect_favicon
      detect_public_file("favicon", %w[ico svg png])
    end

    def detect_public_file(name, extensions)
      extensions.each do |ext|
        path = File.join(Constants::PUBLIC_DIR, "#{name}.#{ext}")
        return "#{name}.#{ext}" if File.exist?(path)
      end
      nil
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
        credits: config.branding.credits != false,
        copyright: config.branding.copyright
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

      socials.filter_map { |platform, url| build_social_link(platform.to_s, url) }
    end

    def build_social_link(platform, url)
      return if platform == "custom" || !valid_url?(url)

      { platform: platform, url: url, icon: SOCIAL_ICON_MAP[platform] || platform }
    end

    def valid_url?(url)
      url.is_a?(String) && !url.strip.empty?
    end

    def navigation_options
      cta_items = config.navigation.cta || []
      {
        header_ctas: normalize_cta_items(cta_items)
      }
    end

    def normalize_cta_items(items)
      return [] unless items.is_a?(Array)

      items.first(2).filter_map do |item|
        next unless item.is_a?(Hash) && item["text"] && item["href"]

        {
          text: item["text"],
          href: item["href"],
          variant: item["variant"] || "primary",
          external: item["external"] == true
        }
      end
    end

    def tabs_options
      tab_items = config.tabs || []
      {
        tabs: normalize_tab_items(tab_items),
        has_tabs: tab_items.any?
      }
    end

    def normalize_tab_items(items)
      return [] unless items.is_a?(Array)

      items.filter_map do |item|
        next unless item.is_a?(Hash) && item["text"] && item["href"]

        {
          text: item["text"],
          href: item["href"],
          icon: item["icon"],
          external: item["external"] == true
        }
      end
    end
  end
end
