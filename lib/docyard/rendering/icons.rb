# frozen_string_literal: true

require_relative "icons/file_types"
require_relative "renderer"

module Docyard
  module Icons
    VALID_WEIGHTS = %w[regular bold fill light thin duotone].freeze

    def self.render(name, weight = "regular")
      name = name.to_s.tr("_", "-")
      weight = weight.to_s
      weight = "regular" unless VALID_WEIGHTS.include?(weight)
      weight_class = weight == "regular" ? "ph" : "ph-#{weight}"
      %(<i class="#{weight_class} ph-#{name}" aria-hidden="true"></i>)
    end

    def self.render_file_extension(extension)
      svg_content = FileTypes.svg(extension)

      if svg_content
        Renderer.new.render_partial(
          "_icon_file_extension", {
            extension: extension,
            svg_content: svg_content
          }
        )
      else
        render("file")
      end
    end
  end
end
