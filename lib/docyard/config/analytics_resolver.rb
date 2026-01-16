# frozen_string_literal: true

module Docyard
  module AnalyticsResolver
    def analytics_options
      analytics = config.analytics
      {
        analytics_google: analytics.google,
        analytics_plausible: analytics.plausible,
        analytics_fathom: analytics.fathom,
        analytics_script: analytics.script,
        has_analytics: any_analytics_configured?(analytics)
      }
    end

    private

    def any_analytics_configured?(analytics)
      [analytics.google, analytics.plausible, analytics.fathom, analytics.script].any? do |value|
        value.is_a?(String) && !value.strip.empty?
      end
    end
  end
end
