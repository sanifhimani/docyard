# frozen_string_literal: true

require_relative "icons/phosphor"
require_relative "icons/file_types"
require_relative "renderer"

module Docyard
  module Icons
    LIBRARIES = {
      phosphor: PHOSPHOR
    }.freeze

    def self.render(name, weight = "regular")
      icon_data = LIBRARIES.dig(:phosphor, weight, name)
      return nil unless icon_data

      Renderer.new.render_partial(
        "_icon", {
          name: name,
          icon_data: icon_data
        }
      )
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
