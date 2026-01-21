# frozen_string_literal: true

module Docyard
  module BrandingVariables
    private

    def assign_branding_variables(branding, current_path = "/")
      assign_site_branding(branding)
      assign_search_options(branding)
      assign_credits_and_social(branding)
      assign_tabs(branding, current_path)
      assign_analytics(branding)
    end

    def assign_site_branding(branding)
      @site_title = branding[:site_title] || Constants::DEFAULT_SITE_TITLE
      @site_description = branding[:site_description] || ""
      @logo = branding[:logo] || Constants::DEFAULT_LOGO_PATH
      @logo_dark = branding[:logo_dark]
      @favicon = branding[:favicon] || Constants::DEFAULT_FAVICON_PATH
      @has_custom_logo = branding[:has_custom_logo] || false
      @primary_color = branding[:primary_color]
    end

    def assign_search_options(branding)
      @search_enabled = branding[:search_enabled].nil? || branding[:search_enabled]
      @search_placeholder = branding[:search_placeholder] || "Search documentation..."
    end

    def assign_credits_and_social(branding)
      @credits = branding[:credits] != false
      @copyright = branding[:copyright]
      @social = branding[:social] || []
      @header_ctas = branding[:header_ctas] || []
      @announcement = branding[:announcement]
    end

    def assign_analytics(branding)
      @has_analytics = branding[:has_analytics] || false
      @analytics_google = branding[:analytics_google]
      @analytics_plausible = branding[:analytics_plausible]
      @analytics_fathom = branding[:analytics_fathom]
      @analytics_script = branding[:analytics_script]
    end

    def assign_tabs(branding, current_path)
      tabs = branding[:tabs] || []
      @tabs = tabs.map { |tab| tab.merge(active: tab_active?(tab[:href], current_path)) }
      @has_tabs = branding[:has_tabs] || false
      @current_path = current_path
    end

    def tab_active?(tab_href, current_path)
      return false if tab_href.nil? || current_path.nil?
      return false if tab_href.start_with?("http://", "https://")

      normalized_tab = tab_href.chomp("/")
      normalized_current = current_path.chomp("/")

      return true if normalized_tab == normalized_current

      current_path.start_with?("#{normalized_tab}/")
    end
  end
end
