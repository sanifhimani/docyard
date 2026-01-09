# frozen_string_literal: true

RSpec.describe Docyard::SidebarBuilder do
  include_context "with docs directory"

  let(:current_path) { "/" }
  let(:config) { Docyard::Config.load(temp_dir) }
  let(:sidebar) { described_class.new(docs_path: docs_dir, current_path: current_path, config: config) }

  describe "#tree" do
    context "with empty directory" do
      it "returns empty array" do
        expect(sidebar.tree).to eq([])
      end
    end

    context "with basic structure" do
      before do
        create_doc("getting-started.md", "---\ntitle: Getting Started\n---")
        create_doc("guide.md", "---\ntitle: Guide\n---")
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
        create_doc("guide/index.md", "---\ntitle: Guide Overview\n---")
        create_doc("guide/setup.md", "---\ntitle: Setup\n---")
      end

      it "builds nested tree", :aggregate_failures do
        tree = sidebar.tree

        expect(tree.length).to eq(1)
        expect(tree[0][:type]).to eq(:directory)
        expect(tree[0][:children].length).to eq(2)
      end
    end

    it "returns consistent tree on subsequent calls", :aggregate_failures do
      create_doc("test.md")

      tree1 = sidebar.tree
      tree2 = sidebar.tree

      expect(tree1).to eq(tree2)
      expect(tree1).not_to be_empty
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
        create_doc("getting-started.md", "---\ntitle: Getting Started\n---")
      end

      it "returns HTML string", :aggregate_failures do
        html = sidebar.to_html

        expect(html).to include("<nav>")
        expect(html).to include('href="/getting-started"')
        expect(html).to include(">Getting Started</span>")
      end
    end

    context "with custom site title in config" do
      let(:config) do
        create_config(<<~YAML)
          title: "My Documentation"
        YAML
        Docyard::Config.load(temp_dir)
      end

      before do
        create_doc("index.md", "---\ntitle: My Documentation\n---")
        create_doc("test.md", "---\ntitle: Test Page\n---")
      end

      it "filters site title from navigation", :aggregate_failures do
        html = sidebar.to_html

        expect(html).to include('<a href="/test"')
        expect(html).to include(">Test</span>")
        expect(html).not_to include(">My Documentation</span>")
      end
    end

    context "without site title in config" do
      before do
        create_doc("index.md", "---\ntitle: Documentation\n---")
        create_doc("test.md", "---\ntitle: Test Page\n---")
      end

      it "filters default title from navigation", :aggregate_failures do
        html = sidebar.to_html

        expect(html).to include('<a href="/test"')
        expect(html).to include(">Test</span>")
        expect(html).not_to include(">Documentation</span>")
      end
    end
  end

  describe "integration" do
    let(:current_path) { "/guide/setup" }

    before do
      create_doc("getting-started.md", "---\ntitle: Getting Started\n---\n\nContent")
      create_doc("guide/index.md", "---\ntitle: Guide Overview\n---\n\nContent")
      create_doc("guide/setup.md", "---\ntitle: Setup\n---\n\nContent")
      create_doc("guide/advanced/performance.md", "---\ntitle: Performance\n---\n\nContent")
    end

    it "generates complete sidebar", :aggregate_failures do
      html = sidebar.to_html

      expect(html).to include("<nav>")
      expect(html).to include("Getting Started")
      expect(html).to include("Setup")
      expect(html).to include("Introduction")
      expect(html).to include("Performance")
    end
  end

  describe "with _sidebar.yml" do
    before do
      create_doc("introduction.md", "---\ntitle: Introduction\n---\n")
      create_doc("getting-started.md", "---\ntitle: Getting Started\n---\n")
      create_doc("advanced.md", "---\ntitle: Advanced Topics\n---\n")
    end

    context "when _sidebar.yml exists" do
      before do
        File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
          - introduction
          - getting-started
          - advanced
        YAML
      end

      it "uses _sidebar.yml ordering over filesystem order", :aggregate_failures do
        tree = sidebar.tree

        expect(tree.length).to eq(3)
        expect(tree[0][:title]).to eq("Introduction")
        expect(tree[1][:title]).to eq("Getting Started")
        expect(tree[2][:title]).to eq("Advanced Topics")
      end

      it "renders items in _sidebar.yml order", :aggregate_failures do
        html = sidebar.to_html

        intro_pos = html.index("Introduction")
        getting_started_pos = html.index("Getting Started")
        advanced_pos = html.index("Advanced Topics")

        expect(intro_pos).to be < getting_started_pos
        expect(getting_started_pos).to be < advanced_pos
      end
    end

    context "when _sidebar.yml has invalid YAML" do
      before do
        File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
          invalid: yaml: syntax
        YAML
      end

      it "falls back to filesystem order", :aggregate_failures do
        tree = sidebar.tree

        expect(tree.length).to eq(3)
        # Filesystem order (alphabetical)
        expect(tree.map { |i| i[:title] }).to include("Introduction", "Getting Started", "Advanced Topics")
      end
    end
  end
end
