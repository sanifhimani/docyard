# frozen_string_literal: true

require_relative "sections"

module Docyard
  class Config
    module Schema
      DEFINITION = {
        title: { type: :string },
        description: { type: :string, recommended: true },
        url: { type: :url },
        og_image: { type: :string },
        twitter: { type: :string },
        source: { type: :string },
        sidebar: { type: :enum, values: SIDEBAR_MODES },
        branding: BRANDING_SCHEMA,
        socials: SOCIALS_SCHEMA,
        tabs: TABS_SCHEMA,
        build: BUILD_SCHEMA,
        search: SEARCH_SCHEMA,
        navigation: NAVIGATION_SCHEMA,
        announcement: ANNOUNCEMENT_SCHEMA,
        repo: REPO_SCHEMA,
        analytics: ANALYTICS_SCHEMA,
        feedback: FEEDBACK_SCHEMA
      }.freeze
    end
  end
end
