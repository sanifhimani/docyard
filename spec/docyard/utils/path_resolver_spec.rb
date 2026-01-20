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
end
