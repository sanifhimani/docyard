# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Docyard::Sidebar::TreeBuilder do
  let(:docs_path) { Dir.mktmpdir }
  let(:current_path) { "/" }
  let(:builder) { described_class.new(docs_path: docs_path, current_path: current_path) }

  after { FileUtils.rm_rf(docs_path) }

  def create_file(path, content = "---\ntitle: Title\n---\n\nContent")
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  describe "#build" do
    context "with empty items" do
      it "returns empty array" do
        expect(builder.build([])).to eq([])
      end
    end

    context "with single file" do
      before { create_file("index.md", "---\ntitle: Home\n---") }

      let(:file_items) do
        [{ type: :file, name: "index", path: "index.md" }]
      end

      it "transforms to tree structure", :aggregate_failures do
        result = builder.build(file_items)

        expect(result.length).to eq(1)
        expect(result[0][:title]).to eq("Home")
        expect(result[0][:path]).to eq("/")
        expect(result[0][:type]).to eq(:file)
      end
    end

    context "with directory containing index" do
      before do
        create_file("guide/index.md", "---\ntitle: Guide\n---")
        create_file("guide/setup.md", "---\ntitle: Setup\n---")
      end

      let(:file_items) do
        [{
          type: :directory,
          name: "guide",
          path: "guide",
          children: [
            { type: :file, name: "index", path: "guide/index.md" },
            { type: :file, name: "setup", path: "guide/setup.md" }
          ]
        }]
      end

      it "makes directory clickable", :aggregate_failures do
        result = builder.build(file_items)

        guide = result[0]
        expect(guide[:path]).to eq("/guide")
        expect(guide[:type]).to eq(:directory)
        expect(guide[:collapsible]).to be true
      end

      it "excludes index from children", :aggregate_failures do
        result = builder.build(file_items)

        guide = result[0]
        expect(guide[:children].length).to eq(1)
        expect(guide[:children][0][:title]).to eq("Setup")
      end
    end

    context "with directory without index" do
      before do
        create_file("reference/api.md", "---\ntitle: API\n---")
      end

      let(:file_items) do
        [{
          type: :directory,
          name: "reference",
          path: "reference",
          children: [
            { type: :file, name: "api", path: "reference/api.md" }
          ]
        }]
      end

      it "makes directory non-clickable" do
        result = builder.build(file_items)

        reference = result[0]
        expect(reference[:path]).to be_nil
      end
    end

    context "with active page tracking" do
      let(:current_path) { "/guide/setup" }
      let(:file_items) do
        [
          { type: :file, name: "index", path: "index.md" },
          {
            type: :directory,
            name: "guide",
            path: "guide",
            children: [
              { type: :file, name: "index", path: "guide/index.md" },
              { type: :file, name: "setup", path: "guide/setup.md" }
            ]
          }
        ]
      end

      before do
        create_file("index.md")
        create_file("guide/index.md")
        create_file("guide/setup.md")
      end

      it "marks current page as active", :aggregate_failures do
        result = builder.build(file_items)

        guide = result[1]
        setup = guide[:children][0]

        expect(setup[:active]).to be true
        expect(result[0][:active]).to be false
      end

      it "keeps ancestor directory expanded" do
        result = builder.build(file_items)

        guide = result[1]
        expect(guide[:collapsed]).to be false
      end
    end

    context "with collapsed state management" do
      let(:current_path) { "/other" }
      let(:file_items) do
        [
          {
            type: :directory,
            name: "guide",
            path: "guide",
            children: [
              { type: :file, name: "index", path: "guide/index.md" },
              { type: :file, name: "setup", path: "guide/setup.md" }
            ]
          },
          { type: :file, name: "other", path: "other.md" }
        ]
      end

      before do
        create_file("guide/index.md")
        create_file("guide/setup.md")
        create_file("other.md")
      end

      it "collapses directories not in current path" do
        result = builder.build(file_items)

        guide = result[0]
        expect(guide[:collapsed]).to be true
      end
    end
  end
end
