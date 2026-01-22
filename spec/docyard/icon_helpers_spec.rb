# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::IconHelpers do
  include described_class

  describe "#icon" do
    it "returns a Phosphor icon element for a named icon" do
      result = icon("globe")

      expect(result).to eq('<i class="ph ph-globe" aria-hidden="true"></i>')
    end

    it "converts underscores to hyphens in icon names" do
      result = icon("arrow_right")

      expect(result).to eq('<i class="ph ph-arrow-right" aria-hidden="true"></i>')
    end

    it "supports different icon weights" do
      result = icon("globe", "bold")

      expect(result).to eq('<i class="ph-bold ph-globe" aria-hidden="true"></i>')
    end

    it "defaults to regular weight for invalid weights" do
      result = icon("globe", "invalid")

      expect(result).to eq('<i class="ph ph-globe" aria-hidden="true"></i>')
    end

    it "passes through SVG strings unchanged" do
      svg = '<svg viewBox="0 0 24 24"><path d="M12 2L2 7"/></svg>'
      result = icon(svg)

      expect(result).to eq(svg)
    end

    it "handles SVG strings with leading whitespace" do
      svg = '  <svg viewBox="0 0 24 24"><path d="M12 2"/></svg>'
      result = icon(svg)

      expect(result).to eq(svg)
    end
  end
end
