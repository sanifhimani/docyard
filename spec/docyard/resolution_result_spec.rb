# frozen_string_literal: true

RSpec.describe Docyard::ResolutionResult do
  describe ".found" do
    it "creates a found result", :aggregate_failures do
      result = described_class.found("path/to/file.md")

      expect(result.file_path).to eq("path/to/file.md")
      expect(result.status).to eq(:found)
      expect(result).to be_found
      expect(result).not_to be_not_found
    end

    it "creates a frozen object" do
      result = described_class.found("path/to/file.md")

      expect(result).to be_frozen
    end
  end

  describe ".not_found" do
    it "creates a not found result", :aggregate_failures do
      result = described_class.not_found

      expect(result.file_path).to be_nil
      expect(result.status).to eq(:not_found)
      expect(result).to be_not_found
      expect(result).not_to be_found
    end

    it "creates a frozen object" do
      result = described_class.not_found

      expect(result).to be_frozen
    end
  end

  describe "#found?" do
    it "returns true for found results" do
      result = described_class.found("file.md")

      expect(result.found?).to be true
    end

    it "returns false for not found results" do
      result = described_class.not_found

      expect(result.found?).to be false
    end
  end

  describe "#not_found?" do
    it "returns false for found results" do
      result = described_class.found("file.md")

      expect(result.not_found?).to be false
    end

    it "returns true for not found results" do
      result = described_class.not_found

      expect(result.not_found?).to be true
    end
  end
end
