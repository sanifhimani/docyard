# frozen_string_literal: true

RSpec.describe Docyard::Config::Schema do
  describe ".top_level_keys" do
    it "returns all top-level config keys" do
      keys = described_class.top_level_keys
      expect(keys).to include("title", "description", "branding", "socials")
    end

    it "returns strings not symbols" do
      keys = described_class.top_level_keys
      expect(keys).to all(be_a(String))
    end
  end

  describe ".section_keys" do
    it "returns keys for branding section" do
      keys = described_class.section_keys(:branding)
      expect(keys).to include("logo", "favicon", "credits", "copyright", "color")
    end

    it "returns keys for build section" do
      keys = described_class.section_keys(:build)
      expect(keys).to include("output", "base")
    end

    it "returns empty array for non-hash sections" do
      keys = described_class.section_keys(:title)
      expect(keys).to eq([])
    end

    it "returns empty array for unknown sections" do
      keys = described_class.section_keys(:nonexistent)
      expect(keys).to eq([])
    end
  end

  describe ".validate_keys" do
    let(:valid_keys) { %w[name age city] }

    it "returns empty array when all keys are valid" do
      hash = { "name" => "John", "age" => 30 }
      errors = described_class.validate_keys(hash, valid_keys, context: "test")
      expect(errors).to be_empty
    end

    it "returns errors for unknown keys", :aggregate_failures do
      hash = { "name" => "John", "unknown" => "value" }
      errors = described_class.validate_keys(hash, valid_keys, context: "test")
      expect(errors.size).to eq(1)
      expect(errors.first[:message]).to include("unknown key 'unknown'")
    end

    it "suggests corrections for typos" do
      hash = { "nme" => "John" }
      errors = described_class.validate_keys(hash, valid_keys, context: "test")
      expect(errors.first[:message]).to include("Did you mean 'name'")
    end

    it "returns empty array for non-hash input" do
      errors = described_class.validate_keys("not a hash", valid_keys, context: "test")
      expect(errors).to eq([])
    end

    it "includes context in error" do
      hash = { "unknown" => "value" }
      errors = described_class.validate_keys(hash, valid_keys, context: "sidebar[0]")
      expect(errors.first[:context]).to eq("sidebar[0]")
    end
  end

  describe "DEFINITION" do
    it "defines all expected top-level keys" do
      expected = %i[title description url og_image twitter source sidebar
                    branding socials tabs build search navigation
                    announcement repo analytics feedback]
      expect(described_class::DEFINITION.keys).to match_array(expected)
    end

    it "defines branding as a hash type" do
      expect(described_class::DEFINITION[:branding][:type]).to eq(:hash)
    end

    it "defines sidebar as an enum", :aggregate_failures do
      expect(described_class::DEFINITION[:sidebar][:type]).to eq(:enum)
      expect(described_class::DEFINITION[:sidebar][:values]).to eq(%w[config auto distributed])
    end
  end

  describe "constants" do
    it "defines SIDEBAR_MODES" do
      expect(described_class::SIDEBAR_MODES).to eq(%w[config auto distributed])
    end

    it "defines CTA_VARIANTS" do
      expect(described_class::CTA_VARIANTS).to eq(%w[primary secondary])
    end

    it "defines SIDEBAR_ITEM_KEYS" do
      expect(described_class::SIDEBAR_ITEM_KEYS).to include("text", "icon", "items")
    end

    it "defines SIDEBAR_EXTERNAL_LINK_KEYS" do
      expect(described_class::SIDEBAR_EXTERNAL_LINK_KEYS).to include("link", "text")
    end
  end
end
