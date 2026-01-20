# frozen_string_literal: true

module Docyard
  module IconHelpers
    VALID_WEIGHTS = %w[regular bold fill light thin duotone].freeze

    def icon(name, weight = "regular")
      name = name.to_s.tr("_", "-")
      weight = weight.to_s
      weight = "regular" unless VALID_WEIGHTS.include?(weight)
      weight_class = weight == "regular" ? "ph" : "ph-#{weight}"
      %(<i class="#{weight_class} ph-#{name}" aria-hidden="true"></i>)
    end

    def icon_file_extension(extension)
      Icons.render_file_extension(extension) || ""
    end

    def icon_for_language(language)
      Icons.render_for_language(language) || ""
    end
  end
end
