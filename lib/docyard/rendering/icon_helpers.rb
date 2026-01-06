# frozen_string_literal: true

module Docyard
  module IconHelpers
    def icon(name, weight = "regular")
      Icons.render(name.to_s.tr("_", "-"), weight) || ""
    end

    def icon_file_extension(extension)
      Icons.render_file_extension(extension) || ""
    end
  end
end
