# frozen_string_literal: true

module Docyard
  class Config
    module Schema
      TOP_LEVEL = %w[
        title description url og_image twitter source
        branding socials tabs sidebar
        build search navigation announcement
        repo analytics feedback
      ].freeze

      SECTIONS = {
        "branding" => %w[logo favicon credits copyright color],
        "build" => %w[output base],
        "search" => %w[enabled placeholder exclude],
        "navigation" => %w[cta breadcrumbs],
        "repo" => %w[url branch edit_path edit_link last_updated],
        "analytics" => %w[google plausible fathom script],
        "announcement" => %w[text link button dismissible],
        "feedback" => %w[enabled question]
      }.freeze

      TAB = %w[text href icon external].freeze

      CTA = %w[text href variant external].freeze

      ANNOUNCEMENT_BUTTON = %w[text link].freeze

      SIDEBAR_ITEM = %w[text icon badge badge_type items collapsed index group collapsible].freeze

      SIDEBAR_EXTERNAL_LINK = %w[link text icon target].freeze

      SOCIALS_BUILTIN = %w[github twitter discord slack linkedin youtube bluesky custom].freeze
    end
  end
end
