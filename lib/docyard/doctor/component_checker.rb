# frozen_string_literal: true

require_relative "component_checkers/base"
require_relative "component_checkers/callout_checker"
require_relative "component_checkers/tabs_checker"
require_relative "component_checkers/cards_checker"
require_relative "component_checkers/steps_checker"
require_relative "component_checkers/code_group_checker"
require_relative "component_checkers/details_checker"
require_relative "component_checkers/badge_checker"
require_relative "component_checkers/icon_checker"
require_relative "component_checkers/tooltip_checker"
require_relative "component_checkers/abbreviation_checker"
require_relative "component_checkers/unknown_type_checker"

module Docyard
  class Doctor
    class ComponentChecker
      CHECKERS = [
        ComponentCheckers::CalloutChecker,
        ComponentCheckers::TabsChecker,
        ComponentCheckers::CardsChecker,
        ComponentCheckers::StepsChecker,
        ComponentCheckers::CodeGroupChecker,
        ComponentCheckers::DetailsChecker,
        ComponentCheckers::BadgeChecker,
        ComponentCheckers::IconChecker,
        ComponentCheckers::TooltipChecker,
        ComponentCheckers::AbbreviationChecker,
        ComponentCheckers::UnknownTypeChecker
      ].freeze

      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
      end

      def check
        CHECKERS.flat_map { |checker_class| checker_class.new(docs_path).check }
      end
    end
  end
end
