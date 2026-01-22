# frozen_string_literal: true

require_relative "logo_detector"
require_relative "analytics_resolver"

module Docyard
  class BrandingResolver
    include AnalyticsResolver

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
      [
        site_options, logo_options, search_options, credits_options, social_options,
        navigation_options, tabs_options, announcement_options, repo_options, analytics_options,
        color_options
      ].reduce({}, :merge)
    end

    def site_options
      {
        site_title: config.title || Constants::DEFAULT_SITE_TITLE,
        site_description: config.description || "",
        site_url: config.url,
        og_image: config.og_image,
        twitter: config.twitter,
        favicon: config.branding.favicon || LogoDetector.auto_detect_favicon(public_dir: config.public_dir)
      }
    end

    def logo_options
      branding = config.branding
      logo = branding.logo || LogoDetector.auto_detect_logo(public_dir: config.public_dir)
      has_custom_logo = !logo.nil?
      {
        logo: logo || Constants::DEFAULT_LOGO_PATH,
        logo_dark: LogoDetector.detect_dark_logo(logo, public_dir: config.public_dir) || Constants::DEFAULT_LOGO_DARK_PATH,
        has_custom_logo: has_custom_logo
      }
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
      { social: normalize_social_links(config.socials || {}) }
    end

    def normalize_social_links(socials)
      return [] unless socials.is_a?(Hash) && socials.any?

      socials.except("custom").filter_map { |platform, url| build_social_link(platform.to_s, url) } +
        build_custom_social_links(socials["custom"])
    end

    def build_social_link(platform, url)
      { platform: platform, url: url, icon: Constants::SOCIAL_ICON_MAP[platform] || platform } if valid_url?(url)
    end

    def build_custom_social_links(custom)
      return [] unless custom.is_a?(Array)

      custom.filter_map do |item|
        next unless item.is_a?(Hash) && item["icon"] && valid_url?(item["href"])

        { platform: "custom", url: item["href"], icon: item["icon"] }
      end
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

    def announcement_options
      announcement = config.announcement
      return { announcement: nil } unless announcement

      {
        announcement: {
          text: announcement.text,
          link: announcement.link,
          button: build_announcement_button(announcement),
          dismissible: announcement.dismissible != false
        }
      }
    end

    def build_announcement_button(announcement)
      button = announcement.button
      return nil unless button.is_a?(Hash) && button["text"]

      {
        text: button["text"],
        link: button["link"] || announcement.link
      }
    end

    def repo_options
      repo = config.repo
      has_repo_url = !repo.url.nil? && !repo.url.empty?
      {
        repo_url: repo.url,
        repo_branch: repo.branch || "main",
        repo_edit_path: repo.edit_path || config.source,
        show_edit_link: has_repo_url && repo.edit_link != false,
        show_last_updated: has_repo_url && repo.last_updated != false
      }
    end

    def color_options
      color = config.branding.color
      { primary_color: normalize_color(color) }
    end

    def normalize_color(color)
      return nil if color.nil?

      if color.is_a?(Hash)
        light = color["light"]
        dark = color["dark"]
        return nil if light.nil? && dark.nil?

        { light: light, dark: dark }.compact
      elsif color.is_a?(String) && !color.strip.empty?
        { light: color.strip }
      end
    end
  end
end
