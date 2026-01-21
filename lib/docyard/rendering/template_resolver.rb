# frozen_string_literal: true

module Docyard
  class TemplateResolver
    BACKGROUNDS = %w[grid glow mesh none].freeze
    DEFAULT_BACKGROUND = "grid"

    attr_reader :frontmatter, :site_config

    def initialize(frontmatter, site_config = {})
      @frontmatter = frontmatter || {}
      @site_config = site_config || {}
    end

    def landing?
      landing_config.any?
    end

    def template
      landing? ? "splash" : "default"
    end

    def show_sidebar?
      if landing?
        landing_config.fetch("sidebar", false)
      else
        true
      end
    end

    def show_toc?
      return false if landing?

      true
    end

    def hero_config
      return nil unless landing?

      hero = landing_config["hero"]
      return nil unless hero.is_a?(Hash)

      symbolize_hero(hero)
    end

    def features_config
      return nil unless landing?

      features = landing_config["features"]
      return nil unless features.is_a?(Array)

      features.map { |f| symbolize_feature(f) }
    end

    def features_header_config
      return nil unless landing?

      header = landing_config["features_header"]
      return nil unless header.is_a?(Hash)

      {
        label: header["label"],
        title: header["title"],
        description: header["description"]
      }.compact
    end

    def footer_config
      return nil unless landing?

      footer = landing_config["footer"]
      return nil unless footer.is_a?(Hash)

      {
        links: normalize_footer_links(footer["links"])
      }
    end

    def to_options
      {
        template: template,
        landing: landing?,
        show_sidebar: show_sidebar?,
        show_toc: show_toc?,
        hero: hero_config,
        features: features_config,
        features_header: features_header_config,
        footer: footer_config
      }
    end

    private

    def normalize_footer_links(links)
      return nil unless links.is_a?(Array)

      links.map do |link|
        next unless link.is_a?(Hash)

        { text: link["text"], link: link["link"] }
      end.compact
    end

    def landing_config
      @landing_config ||= frontmatter["landing"] || site_config["landing"] || {}
    end

    def symbolize_hero(hero)
      background = hero["background"]
      validated_bg = BACKGROUNDS.include?(background) ? background : DEFAULT_BACKGROUND

      {
        background: validated_bg,
        badge: hero["badge"],
        name: hero["name"],
        title: hero["title"],
        tagline: hero["tagline"],
        gradient: hero.fetch("gradient", true),
        image: symbolize_image(hero["image"]),
        custom_visual: symbolize_custom_visual(hero["custom_visual"]),
        actions: symbolize_actions(hero["actions"])
      }.compact
    end

    def symbolize_image(image)
      return nil unless image.is_a?(Hash)

      if image["light"] || image["dark"]
        {
          light: image["light"],
          dark: image["dark"],
          alt: image["alt"]
        }.compact
      else
        {
          src: image["src"],
          alt: image["alt"]
        }.compact
      end
    end

    def symbolize_custom_visual(custom_visual)
      return nil if custom_visual.nil?

      if custom_visual.is_a?(String)
        { html: custom_visual, placement: "side" }
      elsif custom_visual.is_a?(Hash)
        {
          html: custom_visual["html"],
          placement: custom_visual["placement"] || "side"
        }
      end
    end

    def symbolize_actions(actions)
      return nil unless actions.is_a?(Array)

      actions.map do |action|
        {
          text: action["text"],
          link: action["link"],
          icon: action["icon"],
          variant: action["variant"] || "primary",
          target: action["target"],
          rel: action["rel"]
        }.compact
      end
    end

    def symbolize_feature(feature)
      return {} unless feature.is_a?(Hash)

      {
        title: feature["title"],
        description: feature["description"],
        icon: feature["icon"],
        color: feature["color"],
        link: feature["link"],
        link_text: feature["link_text"],
        size: feature["size"],
        target: feature["target"],
        rel: feature["rel"]
      }.compact
    end
  end
end
