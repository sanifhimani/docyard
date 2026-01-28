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

end
