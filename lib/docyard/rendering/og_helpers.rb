# frozen_string_literal: true

module Docyard
  module OgHelpers
    SOCIAL_CARDS_OUTPUT_DIR = "_docyard/og"

    def assign_og_variables(branding, page_description, page_og_image, current_path)
      site_url = branding[:site_url]
      @og_enabled = !site_url.nil? && !site_url.empty?
      return unless @og_enabled

      @og_url = build_canonical_url(site_url, current_path)
      @og_description = page_description || @site_description
      @og_image = resolve_og_image(site_url, page_og_image, branding, current_path)
      @og_twitter = branding[:twitter]
    end

    private

    def resolve_og_image(site_url, page_og_image, branding, current_path)
      explicit_image = page_og_image || branding[:og_image]
      return build_og_image_url(site_url, explicit_image) if explicit_image

      return nil unless branding[:social_cards_enabled]

      generated_card_path = social_card_path_for(current_path)
      build_og_image_url(site_url, generated_card_path)
    end

    def social_card_path_for(current_path)
      path = current_path.delete_prefix("/")
      path = "index" if path.empty?
      "/#{SOCIAL_CARDS_OUTPUT_DIR}/#{path}.png"
    end

    def build_canonical_url(site_url, current_path)
      base = site_url.chomp("/")
      path = current_path.start_with?("/") ? current_path : "/#{current_path}"
      "#{base}#{path}"
    end

    def build_og_image_url(site_url, og_image)
      return nil if og_image.nil?

      if og_image.start_with?("http://", "https://")
        og_image
      else
        base = site_url.chomp("/")
        path = og_image.start_with?("/") ? og_image : "/#{og_image}"
        "#{base}#{path}"
      end
    end
  end
end
