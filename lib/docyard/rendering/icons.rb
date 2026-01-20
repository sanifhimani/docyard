# frozen_string_literal: true

require_relative "icons/devicons"

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

    def self.render_for_language(language)
      devicon_class = Devicons::MAP[language.to_s.downcase]
      return %(<i class="#{devicon_class}" aria-hidden="true"></i>) if devicon_class

      ""
    end

    def self.render_file_extension(extension)
      devicon_class = Devicons::MAP[extension.to_s.downcase]
      return %(<i class="#{devicon_class}" aria-hidden="true"></i>) if devicon_class

      ""
    end

    def self.highlight_language(language)
      Devicons::HIGHLIGHT_ALIASES[language.to_s.downcase] || language
    end

    def self.devicon?(language)
      Devicons::MAP.key?(language.to_s.downcase)
    end
  end
end
