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
require_relative "component_checkers/image_attrs_checker"
require_relative "component_checkers/space_after_colons_checker"
require_relative "component_checkers/unknown_type_checker"

module Docyard
  class Doctor
    class ComponentChecker
      CHECKER_CLASSES = [
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
        ComponentCheckers::ImageAttrsChecker,
        ComponentCheckers::SpaceAfterColonsChecker,
        ComponentCheckers::UnknownTypeChecker
      ].freeze

      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
        @checkers = CHECKER_CLASSES.map { |klass| klass.new(docs_path) }
      end

      def check_file(content, file_path)
        @checkers.flat_map { |checker| checker.check_file(content, file_path) }
      end
    end
  end
end
