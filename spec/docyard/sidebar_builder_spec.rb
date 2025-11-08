# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Docyard::SidebarBuilder do
  let(:docs_path) { Dir.mktmpdir }
  let(:current_path) { "/" }
  let(:config) { {} }
  let(:sidebar) { described_class.new(docs_path: docs_path, current_path: current_path, config: config) }

  after { FileUtils.rm_rf(docs_path) }

  def create_file(path, content = "---\ntitle: Test\n---\n\nContent")
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  describe "#tree" do
    context "with empty directory" do
      it "returns empty array" do
        expect(sidebar.tree).to eq([])
      end
    end

    context "with basic structure" do
      before do
        create_file("getting-started.md", "---\ntitle: Getting Started\n---")
        create_file("guide.md", "---\ntitle: Guide\n---")
      end

      it "returns tree structure", :aggregate_failures do
        tree = sidebar.tree

        expect(tree.length).to eq(2)
        expect(tree[0][:title]).to eq("Getting Started")
        expect(tree[1][:title]).to eq("Guide")
      end
    end

    context "with nested structure" do
      before do
        create_file("guide/index.md", "---\ntitle: Guide Overview\n---")
        create_file("guide/setup.md", "---\ntitle: Setup\n---")
      end

      it "builds nested tree", :aggregate_failures do
        tree = sidebar.tree

        expect(tree.length).to eq(1)
        expect(tree[0][:type]).to eq(:directory)
        expect(tree[0][:children].length).to eq(2)
      end
    end

    it "caches tree on subsequent calls" do
      create_file("test.md")

      tree1 = sidebar.tree
      tree2 = sidebar.tree

      expect(tree1.object_id).to eq(tree2.object_id)
    end
  end

  describe "#to_html" do
    context "with empty tree" do
      it "returns empty string" do
        expect(sidebar.to_html).to eq("")
      end
    end

    context "with files" do
      before do
        create_file("getting-started.md", "---\ntitle: Getting Started\n---")
      end

      it "returns HTML string", :aggregate_failures do
        html = sidebar.to_html

        expect(html).to include("<nav>")
        expect(html).to include('<a href="/getting-started">Getting Started</a>')
      end
    end

    context "with custom site title in config" do
      let(:config) { { site_title: "My Documentation" } }

      before do
        create_file("index.md", "---\ntitle: My Documentation\n---")
        create_file("test.md", "---\ntitle: Test Page\n---")
      end

      it "filters site title from navigation", :aggregate_failures do
        html = sidebar.to_html

        expect(html).to include('<a href="/test"')
        expect(html).to include(">Test</a>")
        expect(html).not_to include(">My Documentation</a>")
      end
    end

    context "without site title in config" do
      before do
        create_file("index.md", "---\ntitle: Documentation\n---")
        create_file("test.md", "---\ntitle: Test Page\n---")
      end

      it "filters default title from navigation", :aggregate_failures do
        html = sidebar.to_html

        expect(html).to include('<a href="/test"')
        expect(html).to include(">Test</a>")
        expect(html).not_to include(">Documentation</a>")
      end
    end
  end

  describe "integration" do
    before do
      create_file("getting-started.md", "---\ntitle: Getting Started\n---\n\nContent")
      create_file("guide/index.md", "---\ntitle: Guide Overview\n---\n\nContent")
      create_file("guide/setup.md", "---\ntitle: Setup\n---\n\nContent")
      create_file("guide/advanced/performance.md", "---\ntitle: Performance\n---\n\nContent")
    end

    let(:current_path) { "/guide/setup" }

    it "generates complete sidebar", :aggregate_failures do
      html = sidebar.to_html

      expect(html).to include("<nav>")
      expect(html).to include("Getting Started")
      expect(html).to include("Setup")
      expect(html).to include("Guide Overview")
      expect(html).to include("Performance")
    end
  end
end
