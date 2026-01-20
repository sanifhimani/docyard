# frozen_string_literal: true

RSpec.describe Docyard::Utils::HashUtils do
  describe ".deep_merge" do
    it "merges top-level keys" do
      hash1 = { a: 1, b: 2 }
      hash2 = { c: 3 }

      expect(described_class.deep_merge(hash1, hash2)).to eq({ a: 1, b: 2, c: 3 })
    end

    it "overwrites values from hash2" do
      hash1 = { a: 1 }
      hash2 = { a: 2 }

      expect(described_class.deep_merge(hash1, hash2)).to eq({ a: 2 })
    end

    it "preserves original value when hash2 has nil" do
      hash1 = { a: 1, b: 2 }
      hash2 = { a: nil, b: 3 }

      result = described_class.deep_merge(hash1, hash2)

      expect(result).to eq({ a: 1, b: 3 })
    end

    it "recursively merges nested hashes" do
      hash1 = { a: { b: 1, c: 2 } }
      hash2 = { a: { c: 3, d: 4 } }

      result = described_class.deep_merge(hash1, hash2)

      expect(result).to eq({ a: { b: 1, c: 3, d: 4 } })
    end

    it "handles deeply nested hashes" do
      hash1 = { a: { b: { c: 1 } } }
      hash2 = { a: { b: { d: 2 } } }

      result = described_class.deep_merge(hash1, hash2)

      expect(result).to eq({ a: { b: { c: 1, d: 2 } } })
    end

    it "replaces non-hash values with hash values" do
      hash1 = { a: 1 }
      hash2 = { a: { b: 2 } }

      result = described_class.deep_merge(hash1, hash2)

      expect(result).to eq({ a: { b: 2 } })
    end

    it "replaces hash values with non-hash values" do
      hash1 = { a: { b: 2 } }
      hash2 = { a: 1 }

      result = described_class.deep_merge(hash1, hash2)

      expect(result).to eq({ a: 1 })
    end
  end

  describe ".deep_dup" do
    it "creates a copy of a simple hash", :aggregate_failures do
      original = { a: 1, b: 2 }
      copy = described_class.deep_dup(original)

      expect(copy).to eq(original)
      expect(copy).not_to be(original)
    end

    it "deeply copies nested hashes" do
      original = { a: { b: 1 } }
      copy = described_class.deep_dup(original)

      copy[:a][:b] = 999

      expect(original[:a][:b]).to eq(1)
    end

    it "deeply copies arrays" do
      original = { a: [1, 2, 3] }
      copy = described_class.deep_dup(original)

      copy[:a] << 4

      expect(original[:a]).to eq([1, 2, 3])
    end

    it "deeply copies hashes inside arrays" do
      original = { items: [{ name: "one" }, { name: "two" }] }
      copy = described_class.deep_dup(original)

      copy[:items][0][:name] = "modified"

      expect(original[:items][0][:name]).to eq("one")
    end

    it "handles mixed nested structures" do
      original = {
        level1: {
          level2: {
            items: [{ id: 1 }, { id: 2 }]
          }
        }
      }
      copy = described_class.deep_dup(original)

      copy[:level1][:level2][:items][0][:id] = 999

      expect(original[:level1][:level2][:items][0][:id]).to eq(1)
    end

    it "preserves non-hash non-array values" do
      original = { a: 1, b: "string", c: :symbol, d: true }
      copy = described_class.deep_dup(original)

      expect(copy).to eq(original)
    end
  end
end
