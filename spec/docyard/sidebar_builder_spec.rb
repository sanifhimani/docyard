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
      expect(html).to include("Overview")
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
        expect(tree.map { |i| i[:title] }).to include("Introduction", "Getting Started", "Advanced Topics")
      end
    end
  end

  describe "distributed vs root _sidebar.yml consistency" do
    let(:current_path) { "/guide/installation" }

    before do
      create_doc("guide/index.md", "---\ntitle: Guide Overview\n---")
      create_doc("guide/installation.md", "---\ntitle: Installation\n---")
      create_doc("guide/configuration.md", "---\ntitle: Configuration\n---")
    end

    context "with root _sidebar.yml using section wrapper" do
      let(:config) do
        create_config(<<~YAML)
          tabs:
            - text: Guide
              href: /guide
        YAML
        Docyard::Config.load(temp_dir)
      end

      before do
        File.write(File.join(docs_dir, "guide", "_sidebar.yml"), <<~YAML)
          - _:
              text: Guide
              icon: book
              section: true
              items:
                - index:
                    text: Overview
                - installation:
                    text: Installation
                - configuration:
                    text: Configuration
        YAML
      end

      it "renders section as top-level group", :aggregate_failures do
        tree = sidebar.tree

        expect(tree.length).to eq(1)
        expect(tree[0][:section]).to be true
        expect(tree[0][:title]).to eq("Guide")
      end

      it "includes all children under section", :aggregate_failures do
        tree = sidebar.tree
        children = tree[0][:children]

        expect(children.length).to eq(3)
        expect(children.map { |c| c[:title] }).to eq(%w[Overview Installation Configuration])
      end

      it "prefixes paths correctly", :aggregate_failures do
        tree = sidebar.tree
        children = tree[0][:children]

        expect(children[0][:path]).to eq("/guide")
        expect(children[1][:path]).to eq("/guide/installation")
        expect(children[2][:path]).to eq("/guide/configuration")
      end

      it "marks correct item as active", :aggregate_failures do
        tree = sidebar.tree
        children = tree[0][:children]

        expect(children[1][:active]).to be true
        expect(children[0][:active]).to be false
        expect(children[2][:active]).to be false
      end
    end

    context "with simple list _sidebar.yml" do
      let(:config) do
        create_config(<<~YAML)
          tabs:
            - text: Guide
              href: /guide
        YAML
        Docyard::Config.load(temp_dir)
      end

      before do
        File.write(File.join(docs_dir, "guide", "_sidebar.yml"), <<~YAML)
          - installation:
              text: Installation
          - configuration:
              text: Configuration
        YAML
      end

      it "auto-prepends Overview when index.md exists", :aggregate_failures do
        tree = sidebar.tree

        expect(tree.length).to eq(3)
        expect(tree[0][:title]).to eq("Overview")
        expect(tree[0][:path]).to eq("/guide")
      end

      it "renders configured items in order", :aggregate_failures do
        tree = sidebar.tree

        expect(tree[1][:title]).to eq("Installation")
        expect(tree[2][:title]).to eq("Configuration")
      end
    end
  end

  describe "tab-based sidebar scoping" do
    let(:current_path) { "/guide/setup" }

    before do
      create_doc("guide/index.md", "---\ntitle: Guide\n---")
      create_doc("guide/setup.md", "---\ntitle: Setup\n---")
      create_doc("api/index.md", "---\ntitle: API\n---")
      create_doc("api/reference.md", "---\ntitle: Reference\n---")
    end

    context "without tabs configured" do
      it "shows all docs in sidebar", :aggregate_failures do
        tree = sidebar.tree

        titles = extract_all_titles(tree)
        expect(titles).to include("Guide", "Api")
      end
    end

    context "with tabs configured on guide section" do
      let(:config) do
        create_config(<<~YAML)
          tabs:
            - text: Guide
              href: /guide
            - text: API
              href: /api
        YAML
        Docyard::Config.load(temp_dir)
      end
      let(:current_path) { "/guide/setup" }

      it "shows only guide section in sidebar", :aggregate_failures do
        tree = sidebar.tree

        titles = extract_all_titles(tree)
        expect(titles).to include("Setup")
        expect(titles).not_to include("Reference")
      end
    end

    context "with tabs configured on api section" do
      let(:config) do
        create_config(<<~YAML)
          tabs:
            - text: Guide
              href: /guide
            - text: API
              href: /api
        YAML
        Docyard::Config.load(temp_dir)
      end
      let(:current_path) { "/api/reference" }

      it "shows only api section in sidebar", :aggregate_failures do
        tree = sidebar.tree

        titles = extract_all_titles(tree)
        expect(titles).to include("Reference")
        expect(titles).not_to include("Setup")
      end
    end

    context "with scoped _sidebar.yml in tab folder" do
      let(:config) do
        create_config(<<~YAML)
          tabs:
            - text: Guide
              href: /guide
        YAML
        Docyard::Config.load(temp_dir)
      end

      before do
        File.write(File.join(docs_dir, "guide", "_sidebar.yml"), <<~YAML)
          - setup:
              text: Getting Setup
              icon: wrench
        YAML
      end

      it "uses folder-specific _sidebar.yml", :aggregate_failures do
        tree = sidebar.tree

        setup_item = tree.find { |i| i[:title] == "Getting Setup" }
        expect(setup_item).not_to be_nil
        expect(setup_item[:icon]).to eq("wrench")
      end
    end
  end

  private

  def extract_all_titles(tree)
    tree.flat_map do |item|
      [item[:title]] + extract_all_titles(item[:children] || [])
    end
  end
end
