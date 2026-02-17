# frozen_string_literal: true

module Docyard
  class Error < StandardError; end

  class ConfigError < Error; end

  class SidebarConfigError < Error; end

  class BuildError < Error; end

  class DeployError < Error; end
end
