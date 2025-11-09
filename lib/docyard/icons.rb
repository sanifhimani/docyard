# frozen_string_literal: true

require_relative "icons/phosphor"

module Docyard
  module Icons
    LIBRARIES = {
      phosphor: PHOSPHOR
    }.freeze

    def self.render(name, weight = "regular", library: :phosphor)
      icon_data = LIBRARIES.dig(library, weight, name)
      return nil unless icon_data

      <<~HTML.strip
        <span class="docyard-icon docyard-icon-#{name}" aria-hidden="true"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" fill="currentColor">#{icon_data}</svg></span>
      HTML
    end
  end
end
