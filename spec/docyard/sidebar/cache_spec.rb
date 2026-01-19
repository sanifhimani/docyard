# frozen_string_literal: true

RSpec.describe Docyard::Sidebar::Cache do
  include_context "with docs directory"

  let(:config) { instance_double(Docyard::Config, sidebar: sidebar_mode) }
  let(:sidebar_mode) { "auto" }
  let(:cache) { described_class.new(docs_path: docs_dir, config: config) }

  def find_item(items, title)
    items.find { |i| i[:title] == title }
  end

  before do
    create_doc("guide.md", "# Guide")
    create_doc("reference.md", "# Reference")
  end

  describe "#build" do
    it "builds and caches the tree", :aggregate_failures do
      result = cache.build

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
    end

    it "sets built_at timestamp" do
      cache.build

      expect(cache.built_at).to be_a(Time)
    end

    it "stores tree for later retrieval" do
      cache.build

      expect(cache.tree).not_to be_nil
    end

    context "with auto sidebar mode" do
      let(:sidebar_mode) { "auto" }

      it "uses AutoBuilder" do
        result = cache.build

        expect(result.first[:title]).to eq("Guide")
      end
    end

    context "with config sidebar mode" do
      let(:sidebar_mode) { nil }

      before do
        create_file("_sidebar.yml", "- guide\n- reference")
      end

      it "uses ConfigBuilder with local config" do
        result = cache.build

        expect(result).to be_an(Array)
      end
    end
  end

  describe "#get" do
    context "when tree is not built" do
      it "returns nil" do
        expect(cache.get(current_path: "/guide")).to be_nil
      end
    end

    context "when tree is built" do
      before { cache.build }

      it "returns tree with active items marked" do
        result = cache.get(current_path: "/guide")
        guide = find_item(result, "Guide")

        expect(guide[:active]).to be true
      end

      it "does not modify original tree", :aggregate_failures do
        cache.get(current_path: "/guide")
        original_guide = find_item(cache.tree, "Guide")

        expect(original_guide[:active]).to be false
      end

      it "marks different items active for different paths", :aggregate_failures do
        result1 = cache.get(current_path: "/guide")
        result2 = cache.get(current_path: "/reference")

        guide1 = find_item(result1, "Guide")
        guide2 = find_item(result2, "Guide")

        expect(guide1[:active]).to be true
        expect(guide2[:active]).to be false
      end
    end
  end

  describe "#invalidate" do
    before { cache.build }

    it "clears the tree" do
      cache.invalidate

      expect(cache.tree).to be_nil
    end

    it "clears built_at" do
      cache.invalidate

      expect(cache.built_at).to be_nil
    end
  end

  describe "#valid?" do
    it "returns false when tree is not built" do
      expect(cache.valid?).to be false
    end

    it "returns true when tree is built" do
      cache.build

      expect(cache.valid?).to be true
    end

    it "returns false after invalidation" do
      cache.build
      cache.invalidate

      expect(cache.valid?).to be false
    end
  end

  describe "active state with nested items" do
    before do
      create_doc("guide/intro.md", "# Intro")
      create_doc("guide/advanced.md", "# Advanced")
      cache.build
    end

    it "marks nested item as active" do
      result = cache.get(current_path: "/guide/intro")
      guide = find_item(result, "Guide")
      intro = find_item(guide[:children], "Intro")

      expect(intro[:active]).to be true
    end

    it "expands parent when child is active", :aggregate_failures do
      result = cache.get(current_path: "/guide/intro")
      guide = find_item(result, "Guide")

      expect(guide[:collapsed]).to be false
    end
  end

  describe "path normalization" do
    before { cache.build }

    it "handles paths with trailing slashes" do
      result = cache.get(current_path: "/guide/")
      guide = find_item(result, "Guide")

      expect(guide[:active]).to be true
    end

    it "handles paths without leading slash" do
      result = cache.get(current_path: "guide")
      guide = find_item(result, "Guide")

      expect(guide[:active]).to be true
    end
  end
end
