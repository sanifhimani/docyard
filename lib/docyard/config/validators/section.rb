# frozen_string_literal: true

module Docyard
  class Config
    module Validators
      module Section
        private

        def validate_top_level
          validate_string(@config["title"], "title")
          validate_string(@config["description"], "description")
        end

        def validate_branding_section
          branding = @config["branding"]
          return unless branding

          validate_file_path_or_url(branding["logo"], "branding.logo")
          validate_file_path_or_url(branding["favicon"], "branding.favicon")
          validate_boolean(branding["credits"], "branding.credits") if branding.key?("credits")
        end

        def validate_socials_section
          socials = @config["socials"]
          return unless socials
          return add_hash_error("socials") unless socials.is_a?(Hash)

          socials.each { |platform, url| validate_url(url, "socials.#{platform}") unless platform == "custom" }
          validate_custom_socials(socials["custom"]) if socials.key?("custom")
        end

        def validate_custom_socials(custom)
          return if custom.nil?
          return add_array_error("socials.custom") unless custom.is_a?(Array)

          custom.each_with_index do |item, index|
            validate_string(item["icon"], "socials.custom[#{index}].icon")
            validate_url(item["href"], "socials.custom[#{index}].href")
          end
        end

        def validate_tabs_section
          tabs = @config["tabs"]
          return unless tabs
          return add_array_error("tabs") unless tabs.is_a?(Array)

          tabs.each_with_index do |tab, index|
            validate_string(tab["text"], "tabs[#{index}].text")
            validate_string(tab["href"], "tabs[#{index}].href")
            validate_boolean(tab["external"], "tabs[#{index}].external") if tab.key?("external")
          end
        end

        def validate_sidebar_setting
          sidebar = @config["sidebar"]
          return if sidebar.nil? || Config::SIDEBAR_MODES.include?(sidebar)

          add_error(
            field: "sidebar",
            error: "must be one of: #{Config::SIDEBAR_MODES.join(', ')}",
            got: sidebar.inspect,
            fix: "Change to 'config', 'auto', or 'distributed'"
          )
        end

        def validate_build_section
          build = @config["build"]
          return unless build

          validate_string(build["output"], "build.output")
          validate_no_slashes(build["output"], "build.output")
          validate_string(build["base"], "build.base")
          validate_starts_with_slash(build["base"], "build.base")
        end

        def validate_search_section
          search = @config["search"]
          return unless search

          validate_boolean(search["enabled"], "search.enabled") if search.key?("enabled")
          validate_string(search["placeholder"], "search.placeholder") if search.key?("placeholder")
          validate_array(search["exclude"], "search.exclude") if search.key?("exclude")
        end

        def validate_announcement_section
          announcement = @config["announcement"]
          return unless announcement.is_a?(Hash)

          validate_string(announcement["text"], "announcement.text") if announcement.key?("text")
        end

        def validate_feedback_section
          feedback = @config["feedback"]
          return unless feedback.is_a?(Hash) && feedback["enabled"] == true
          return if analytics_configured?

          add_error(
            field: "feedback.enabled",
            error: "requires analytics to be configured",
            got: "feedback enabled without analytics",
            fix: "Configure analytics (google, plausible, fathom, or script) to collect feedback responses"
          )
        end

        def analytics_configured?
          analytics = @config["analytics"]
          return false unless analytics.is_a?(Hash)

          analytics["google"] || analytics["plausible"] || analytics["fathom"] || analytics["script"]
        end
      end
    end
  end
end
