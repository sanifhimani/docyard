# frozen_string_literal: true

RSpec.describe Docyard::Utils::TextFormatter do
  describe ".titleize" do
    it "converts hyphenated strings to title case" do
      expect(described_class.titleize("getting-started")).to eq("Getting Started")
    end

    it "converts underscored strings to title case" do
      expect(described_class.titleize("user_guide")).to eq("User Guide")
    end

    it "handles mixed separators" do
      expect(described_class.titleize("api-v2_reference")).to eq("Api V2 Reference")
    end

    it "converts 'index' to 'Home'" do
      expect(described_class.titleize("index")).to eq("Home")
    end

    it "handles single words" do
      expect(described_class.titleize("documentation")).to eq("Documentation")
    end

    it "handles already capitalized words" do
      expect(described_class.titleize("API")).to eq("Api")
    end
  end

  describe ".slugify" do
    it "converts strings to lowercase" do
      expect(described_class.slugify("Getting Started")).to eq("getting-started")
    end

    it "replaces spaces with hyphens" do
      expect(described_class.slugify("User Guide")).to eq("user-guide")
    end

    it "removes special characters" do
      expect(described_class.slugify("API v2.0 (Beta)")).to eq("api-v20-beta")
    end

    it "handles multiple spaces" do
      expect(described_class.slugify("Multiple   Spaces")).to eq("multiple-spaces")
    end

    it "handles already slugified strings" do
      expect(described_class.slugify("already-slugified")).to eq("already-slugified")
    end
  end
end
