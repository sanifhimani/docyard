# frozen_string_literal: true

RSpec.describe Docyard::Sidebar::AutoBuilder do
  include_context "with docs directory"

  let(:builder) { described_class.new(docs_dir, current_path: current_path) }
  let(:current_path) { "/" }

  def find_item(items, title)
    items.find { |i| i[:title] == title }
  end

  describe "#build" do
    context "when docs directory does not exist" do
      it "returns empty array" do
        builder = described_class.new("/nonexistent/path")

        expect(builder.build).to eq([])
      end
    end

    context "with markdown files" do
      before do
        create_doc("guide.md", "# Guide")
        create_doc("reference.md", "# Reference")
      end

      it "returns items for each file" do
        result = builder.build

        expect(result.size).to eq(2)
      end

      it "creates items with correct structure", :aggregate_failures do
        result = builder.build
        guide = find_item(result, "Guide")

        expect(guide[:title]).to eq("Guide")
        expect(guide[:path]).to eq("/guide")
        expect(guide[:type]).to eq(:file)
      end

      it "sorts items alphabetically" do
        result = builder.build

        expect(result.map { |i| i[:title] }).to eq(%w[Guide Reference])
      end
    end

    context "with directories" do
      before do
        create_doc("getting-started/index.md", "# Getting Started")
        create_doc("getting-started/installation.md", "# Installation")
      end

      it "creates directory item with children", :aggregate_failures do
        result = builder.build
        dir = find_item(result, "Getting Started")

        expect(dir[:type]).to eq(:directory)
        expect(dir[:children]).not_to be_empty
      end

      it "sets path when directory has index.md", :aggregate_failures do
        result = builder.build
        dir = find_item(result, "Getting Started")

        expect(dir[:path]).to eq("/getting-started")
        expect(dir[:has_index]).to be true
      end

      it "marks top-level directories as sections" do
        result = builder.build
        dir = find_item(result, "Getting Started")

        expect(dir[:section]).to be true
      end
    end

    context "with nested directories" do
      before do
        create_doc("guide/basics/intro.md", "# Intro")
      end

      it "marks nested directories as collapsed by default", :aggregate_failures do
        result = builder.build
        guide = find_item(result, "Guide")
        basics = find_item(guide[:children], "Basics")

        expect(guide[:collapsed]).to be false
        expect(basics[:collapsed]).to be true
      end
    end

    context "with ignored entries" do
      before do
        create_doc("guide.md", "# Guide")
        create_doc(".hidden.md", "# Hidden")
        create_doc("_private.md", "# Private")
        create_doc("index.md", "# Home")
        FileUtils.mkdir_p(File.join(docs_dir, "public"))
      end

      it "ignores files starting with dot" do
        result = builder.build
        titles = result.map { |i| i[:title] }

        expect(titles).not_to include(".hidden")
      end

      it "ignores files starting with underscore", :aggregate_failures do
        result = builder.build
        titles = result.map { |i| i[:title] }

        expect(titles).not_to include("_private")
        expect(titles).not_to include("Private")
      end

      it "ignores root index.md" do
        result = builder.build
        titles = result.map { |i| i[:title] }

        expect(titles).not_to include("Index")
      end

      it "ignores public folder" do
        result = builder.build
        titles = result.map { |i| i[:title] }

        expect(titles).not_to include("Public")
      end
    end

    context "with current path" do
      before do
        create_doc("guide.md", "# Guide")
        create_doc("reference.md", "# Reference")
      end

      let(:current_path) { "/guide" }

      it "marks matching item as active" do
        result = builder.build
        guide = find_item(result, "Guide")

        expect(guide[:active]).to be true
      end

      it "does not mark non-matching items as active" do
        result = builder.build
        reference = find_item(result, "Reference")

        expect(reference[:active]).to be false
      end
    end

    context "with active nested item" do
      before do
        create_doc("guide/intro.md", "# Intro")
        create_doc("guide/advanced.md", "# Advanced")
      end

      let(:current_path) { "/guide/intro" }

      it "expands parent directory when child is active", :aggregate_failures do
        result = builder.build
        guide = find_item(result, "Guide")
        intro = find_item(guide[:children], "Intro")

        expect(intro[:active]).to be true
        expect(guide[:collapsed]).to be false
      end
    end

    context "with empty directories" do
      before do
        FileUtils.mkdir_p(File.join(docs_dir, "empty"))
        create_doc("guide.md", "# Guide")
      end

      it "excludes empty directories" do
        result = builder.build
        titles = result.map { |i| i[:title] }

        expect(titles).not_to include("Empty")
      end
    end
  end
end
