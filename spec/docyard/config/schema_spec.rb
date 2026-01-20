# frozen_string_literal: true

RSpec.describe Docyard::Config::Schema do
  describe "TOP_LEVEL" do
    it "includes all expected top-level keys" do
      expect(described_class::TOP_LEVEL).to include(
        "title", "description", "branding", "build", "sidebar", "tabs", "search", "navigation", "repo", "analytics"
      )
    end
  end

  describe "SECTIONS" do
    it "defines valid keys for branding section" do
      expect(described_class::SECTIONS["branding"]).to eq(%w[logo favicon credits copyright])
    end

    it "defines valid keys for build section" do
      expect(described_class::SECTIONS["build"]).to eq(%w[output base])
    end

    it "defines valid keys for repo section" do
      expect(described_class::SECTIONS["repo"]).to eq(%w[url branch edit_path edit_link last_updated])
    end
  end

  describe "SIDEBAR_ITEM" do
    it "includes expected sidebar item keys" do
      expect(described_class::SIDEBAR_ITEM).to include("text", "icon", "items", "collapsed")
    end
  end
end
