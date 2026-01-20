# frozen_string_literal: true

RSpec.describe Docyard::Config::KeyValidator do
  describe ".validate" do
    let(:valid_keys) { %w[name email age] }

    it "returns empty array when all keys are valid" do
      hash = { "name" => "John", "email" => "john@example.com" }

      result = described_class.validate(hash, valid_keys, context: "user")

      expect(result).to be_empty
    end

    it "returns errors for unknown keys" do
      hash = { "name" => "John", "emial" => "john@example.com" }

      result = described_class.validate(hash, valid_keys, context: "user")

      expect(result.size).to eq(1)
      expect(result.first[:message]).to include("unknown key 'emial'")
    end

    it "suggests similar keys when available" do
      hash = { "nmae" => "John" }

      result = described_class.validate(hash, valid_keys, context: "user")

      expect(result.first[:message]).to include("Did you mean 'name'?")
    end

    it "includes context in errors" do
      hash = { "unknown" => "value" }

      result = described_class.validate(hash, valid_keys, context: "user")

      expect(result.first[:context]).to eq("user")
    end

    it "returns empty array for non-hash input" do
      result = described_class.validate("not a hash", valid_keys, context: "test")

      expect(result).to be_empty
    end

    it "handles symbol keys" do
      hash = { name: "John", emial: "john@example.com" }

      result = described_class.validate(hash, valid_keys, context: "user")

      expect(result.size).to eq(1)
      expect(result.first[:message]).to include("emial")
    end
  end
end
