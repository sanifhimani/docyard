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

    context "with section containing index (depth 1)" do
      before do
        create_file("guide/index.md", "---\n---\n\nContent")
        create_file("guide/setup.md", "---\ntitle: Setup\n---\n\nContent")
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

      it "keeps section header non-clickable", :aggregate_failures do
        result = builder.build(file_items)

        guide = result[0]
        expect(guide[:path]).to be_nil
        expect(guide[:has_index]).to be false
        expect(guide[:type]).to eq(:directory)
      end

      it "creates Overview child as first item", :aggregate_failures do
        result = builder.build(file_items)

        guide = result[0]
        intro = guide[:children].first

        expect(intro[:title]).to eq("Overview")
        expect(intro[:path]).to eq("/guide")
        expect(intro[:type]).to eq(:file)
      end

      it "filters duplicate index from children" do
        result = builder.build(file_items)

        guide = result[0]
        index_children = guide[:children].select { |c| c[:path] == "/guide" }

        expect(index_children.length).to eq(1)
      end

      it "places Introduction before other children", :aggregate_failures do
        result = builder.build(file_items)

        guide = result[0]
        expect(guide[:children].length).to eq(2)
        expect(guide[:children][0][:path]).to eq("/guide")
        expect(guide[:children][1][:path]).to eq("/guide/setup")
      end
    end

    context "with custom sidebar text for section index" do
      before do
        create_file("guide/index.md", "---\nsidebar:\n  text: Getting Started\n---\n\nContent")
        create_file("guide/setup.md")
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

      it "uses custom sidebar text instead of Introduction" do
        result = builder.build(file_items)

        guide = result[0]
        intro = guide[:children].first

        expect(intro[:title]).to eq("Getting Started")
      end
    end

    context "with nested directory containing index (depth 2+)" do
      before do
        create_file("advanced/customization/index.md", "---\nsidebar:\n  text: Customization Overview\n---\n\nContent")
        create_file("advanced/customization/themes.md", "---\ntitle: Themes\n---\n\nContent")
      end

      let(:file_items) do
        [{
          type: :directory,
          name: "advanced",
          path: "advanced",
          children: [
            {
              type: :directory,
              name: "customization",
              path: "advanced/customization",
              children: [
                { type: :file, name: "index", path: "advanced/customization/index.md" },
                { type: :file, name: "themes", path: "advanced/customization/themes.md" }
              ]
            }
          ]
        }]
      end

      it "renders nested directory as collapsible group (not section)", :aggregate_failures do
        result = builder.build(file_items)

        advanced = result[0]
        customization = advanced[:children][0]

        expect(customization[:path]).to eq("/advanced/customization")
        expect(customization[:has_index]).to be true
        expect(customization[:section]).to be false
        expect(customization[:title]).to eq("Customization")
      end

      it "makes header clickable and does NOT add Overview child", :aggregate_failures do
        result = builder.build(file_items)

        advanced = result[0]
        customization = advanced[:children][0]

        expect(customization[:children].length).to eq(1)
        expect(customization[:children][0][:title]).to eq("Themes")
        expect(customization[:children][0][:path]).to eq("/advanced/customization/themes")
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

      it "makes directory non-clickable", :aggregate_failures do
        result = builder.build(file_items)

        reference = result[0]
        expect(reference[:path]).to be_nil
        expect(reference[:has_index]).to be false
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

        guide = result.find { |item| item[:type] == :directory }
        index_item = result.find { |item| item[:type] == :file }
        setup = guide[:children].find { |c| c[:path] == "/guide/setup" }

        expect(setup[:active]).to be true
        expect(index_item[:active]).to be false
      end

      it "expands parent directory when child is active" do
        result = builder.build(file_items)

        guide = result.find { |item| item[:type] == :directory }
        expect(guide[:collapsed]).to be false
      end
    end

    context "when visiting section index URL" do
      let(:current_path) { "/guide" }
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

      before do
        create_file("guide/index.md", "---\n---\n\nContent")
        create_file("guide/setup.md", "---\n---\n\nContent")
      end

      it "marks Introduction item as active", :aggregate_failures do
        result = builder.build(file_items)

        guide = result[0]
        intro = guide[:children].first

        expect(intro[:active]).to be true
        expect(intro[:path]).to eq("/guide")
      end

      it "expands section when Introduction is active" do
        result = builder.build(file_items)

        guide = result[0]
        expect(guide[:collapsed]).to be false
      end
    end

    context "with trailing slash in current path" do
      let(:current_path) { "/guide/setup/" }
      let(:file_items) do
        [
          {
            type: :directory,
            name: "guide",
            path: "guide",
            children: [
              { type: :file, name: "setup", path: "guide/setup.md" }
            ]
          }
        ]
      end

      before do
        create_file("guide/setup.md")
      end

      it "marks page as active even with trailing slash", :aggregate_failures do
        result = builder.build(file_items)

        guide = result[0]
        setup = guide[:children][0]

        expect(setup[:active]).to be true
      end
    end

    context "with no active children" do
      let(:current_path) { "/" }
      let(:file_items) do
        [
          { type: :file, name: "index", path: "index.md" },
          {
            type: :directory,
            name: "guide",
            path: "guide",
            children: [
              { type: :file, name: "setup", path: "guide/setup.md" }
            ]
          }
        ]
      end

      before do
        create_file("index.md")
        create_file("guide/setup.md")
      end

      it "sections are not collapsed (they are static headers)", :aggregate_failures do
        result = builder.build(file_items)

        guide = result.find { |item| item[:type] == :directory }
        expect(guide[:collapsed]).to be false
        expect(guide[:section]).to be true
      end
    end

    context "with frontmatter order field" do
      let(:current_path) { "/" }
      let(:file_items) do
        [
          { type: :file, name: "installation", path: "installation.md" },
          { type: :file, name: "getting-started", path: "getting-started.md" },
          { type: :file, name: "advanced", path: "advanced.md" }
        ]
      end

      before do
        create_file("installation.md", "---\ntitle: Installation\nsidebar:\n  order: 2\n---\n")
        create_file("getting-started.md", "---\ntitle: Getting Started\nsidebar:\n  order: 1\n---\n")
        create_file("advanced.md", "---\ntitle: Advanced\n---\n")
      end

      it "sorts items by order field, then alphabetically" do
        result = builder.build(file_items)

        titles = result.map { |item| item[:title] }
        expect(titles).to eq(["Getting Started", "Installation", "Advanced"])
      end

      it "includes order in the item hash", :aggregate_failures do
        result = builder.build(file_items)

        getting_started = result.find { |item| item[:title] == "Getting Started" }
        advanced = result.find { |item| item[:title] == "Advanced" }

        expect(getting_started[:order]).to eq(1)
        expect(advanced[:order]).to be_nil
      end
    end

    context "with order field on directories" do
      let(:current_path) { "/" }
      let(:file_items) do
        [
          {
            type: :directory,
            name: "api",
            path: "api",
            children: [{ type: :file, name: "overview", path: "api/overview.md" }]
          },
          {
            type: :directory,
            name: "guide",
            path: "guide",
            children: [{ type: :file, name: "intro", path: "guide/intro.md" }]
          }
        ]
      end

      before do
        create_file("api/index.md", "---\nsidebar:\n  order: 2\n---\n")
        create_file("api/overview.md", "---\ntitle: Overview\n---\n")
        create_file("guide/index.md", "---\nsidebar:\n  order: 1\n---\n")
        create_file("guide/intro.md", "---\ntitle: Intro\n---\n")
      end

      it "sorts directories by their index.md order field" do
        result = builder.build(file_items)

        titles = result.map { |item| item[:title] }
        expect(titles).to eq(%w[Guide Api])
      end
    end
  end
end
