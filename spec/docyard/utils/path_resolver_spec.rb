# frozen_string_literal: true

RSpec.describe Docyard::Utils::PathResolver do
  describe ".normalize" do
    it "removes .md extension" do
      expect(described_class.normalize("getting-started.md")).to eq("/getting-started")
    end

    it "removes /index suffix" do
      expect(described_class.normalize("/guide/index")).to eq("/guide")
    end

    it "removes both .md and /index" do
      expect(described_class.normalize("guide/index.md")).to eq("/guide")
    end

    it "adds leading slash if missing" do
      expect(described_class.normalize("getting-started")).to eq("/getting-started")
    end

    it "returns '/' for nil" do
      expect(described_class.normalize(nil)).to eq("/")
    end

    it "returns '/' for empty string" do
      expect(described_class.normalize("")).to eq("/")
    end

    it "returns '/' for 'index.md'" do
      expect(described_class.normalize("index.md")).to eq("/")
    end

    it "preserves already normalized paths" do
      expect(described_class.normalize("/getting-started")).to eq("/getting-started")
    end

    it "handles nested paths" do
      expect(described_class.normalize("/guide/setup.md")).to eq("/guide/setup")
    end

    it "removes trailing slash" do
      expect(described_class.normalize("/guide/setup/")).to eq("/guide/setup")
    end

    it "handles trailing slash with index" do
      expect(described_class.normalize("/guide/index/")).to eq("/guide")
    end
  end

  describe ".to_url" do
    it "converts file path to URL path" do
      expect(described_class.to_url("getting-started.md")).to eq("/getting-started")
    end

    it "is an alias for normalize" do
      path = "guide/index.md"
      expect(described_class.to_url(path)).to eq(described_class.normalize(path))
    end
  end

  describe ".ancestor?" do
    it "returns true when parent is ancestor of child" do
      expect(described_class.ancestor?("/guide", "/guide/setup")).to be true
    end

    it "returns false when paths are equal" do
      expect(described_class.ancestor?("/guide", "/guide")).to be false
    end

    it "returns false when parent is not ancestor" do
      expect(described_class.ancestor?("/api", "/guide/setup")).to be false
    end

    it "returns false when parent is nil" do
      expect(described_class.ancestor?(nil, "/guide/setup")).to be false
    end

    it "returns false when parent is longer than child" do
      expect(described_class.ancestor?("/guide/setup", "/guide")).to be false
    end

    it "returns true for nested paths" do
      expect(described_class.ancestor?("/api", "/api/v1/users")).to be true
    end
  end
end
