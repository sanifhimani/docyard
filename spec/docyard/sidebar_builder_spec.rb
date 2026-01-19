# frozen_string_literal: true

RSpec.describe Docyard::SidebarBuilder do
  include_context "with docs directory"

  let(:current_path) { "/" }
  let(:config) { Docyard::Config.load(temp_dir) }
  let(:sidebar) { described_class.new(docs_path: docs_dir, current_path: current_path, config: config) }

  describe "#tree" do
    context "with empty directory and no config" do
      it "returns empty array" do
        expect(sidebar.tree).to eq([])
      end
    end

    context "with basic structure in auto mode" do
      let(:config) do
        create_config(<<~YAML)
          sidebar: auto
        YAML
        Docyard::Config.load(temp_dir)
      end

      before do
        create_doc("getting-started.md", "---\ntitle: Getting Started\n---")
        create_doc("guide.md", "---\ntitle: Guide\n---")
      end

      it "returns tree structure from filesystem", :aggregate_failures do
        tree = sidebar.tree

        expect(tree.length).to eq(2)
        expect(tree[0][:title]).to eq("Getting Started")
        expect(tree[1][:title]).to eq("Guide")
      end
    end

    context "with nested structure in auto mode" do
      let(:config) do
        create_config(<<~YAML)
          sidebar: auto
        YAML
        Docyard::Config.load(temp_dir)
      end

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

    context "with _sidebar.yml" do
      before do
        create_doc("introduction.md")
        create_doc("getting-started.md")
        create_doc("advanced.md")
        File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
          - introduction
          - getting-started
          - advanced
        YAML
      end

      it "returns consistent tree on subsequent calls", :aggregate_failures do
        tree1 = sidebar.tree
        tree2 = sidebar.tree

        expect(tree1).to eq(tree2)
        expect(tree1).not_to be_empty
      end
    end
  end

  describe "#to_html" do
    context "with empty tree" do
      it "returns empty string" do
        expect(sidebar.to_html).to eq("")
      end
    end

    context "with _sidebar.yml" do
      before do
        create_doc("getting-started.md")
        File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
          - getting-started
        YAML
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
          sidebar: auto
        YAML
        Docyard::Config.load(temp_dir)
      end

      before do
        create_doc("index.md")
        create_doc("test.md")
      end

      it "filters site title from navigation", :aggregate_failures do
        html = sidebar.to_html

        expect(html).to include('<a href="/test"')
        expect(html).to include(">Test</span>")
        expect(html).not_to include(">My Documentation</span>")
      end
    end

    context "without site title in config using auto mode" do
      let(:config) do
        create_config(<<~YAML)
          sidebar: auto
        YAML
        Docyard::Config.load(temp_dir)
      end

      before do
        create_doc("index.md")
        create_doc("test.md")
      end

      it "filters default title from navigation", :aggregate_failures do
        html = sidebar.to_html

        expect(html).to include('<a href="/test"')
        expect(html).to include(">Test</span>")
        expect(html).not_to include(">Documentation</span>")
      end
    end
  end

  describe "integration with auto mode" do
    let(:current_path) { "/guide/setup" }
    let(:config) do
      create_config(<<~YAML)
        sidebar: auto
      YAML
      Docyard::Config.load(temp_dir)
    end

    before do
      create_doc("getting-started.md")
      create_doc("guide/index.md")
      create_doc("guide/setup.md")
      create_doc("guide/advanced/performance.md")
    end

    it "generates complete sidebar", :aggregate_failures do
      html = sidebar.to_html

      expect(html).to include("<nav>")
      expect(html).to include("Getting Started")
      expect(html).to include("Setup")
      expect(html).to include("Performance")
    end
  end

  describe "with _sidebar.yml config mode" do
    before do
      create_doc("introduction.md")
      create_doc("getting-started.md")
      create_doc("advanced.md")
    end

    context "when _sidebar.yml exists with simple format" do
      before do
        File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
          - introduction
          - getting-started
          - advanced: { text: Advanced Topics }
        YAML
      end

      it "uses _sidebar.yml ordering", :aggregate_failures do
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
      let(:config) do
        create_config(<<~YAML)
          sidebar: auto
        YAML
        Docyard::Config.load(temp_dir)
      end

      before do
        File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
          invalid: yaml: syntax
        YAML
      end

      it "falls back to auto mode filesystem order", :aggregate_failures do
        tree = sidebar.tree

        expect(tree.length).to eq(3)
        expect(tree.map { |i| i[:title] }).to include("Introduction", "Getting Started", "Advanced")
      end
    end
  end

  describe "section and group structure" do
    let(:current_path) { "/guide/installation" }

    before do
      create_doc("guide/index.md")
      create_doc("guide/installation.md")
      create_doc("guide/configuration.md")
    end

    context "with section wrapper in _sidebar.yml" do
      before do
        File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
          - guide:
              text: Guide
              icon: book
              items:
                - index: { text: Overview }
                - installation: { text: Installation }
                - configuration: { text: Configuration }
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

      it "builds paths correctly", :aggregate_failures do
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
      before do
        File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
          - guide:
              items:
                - index: { text: Overview }
                - installation: { text: Installation }
                - configuration: { text: Configuration }
        YAML
      end

      it "creates section with children", :aggregate_failures do
        tree = sidebar.tree

        expect(tree.length).to eq(1)
        expect(tree[0][:children].length).to eq(3)
        expect(tree[0][:children][0][:title]).to eq("Overview")
      end

      it "renders configured items in order", :aggregate_failures do
        tree = sidebar.tree
        children = tree[0][:children]

        expect(children[1][:title]).to eq("Installation")
        expect(children[2][:title]).to eq("Configuration")
      end
    end
  end

  describe "tab-based sidebar scoping" do
    let(:current_path) { "/guide/setup" }
    let(:config) do
      create_config(<<~YAML)
        sidebar: auto
      YAML
      Docyard::Config.load(temp_dir)
    end

    before do
      create_doc("guide/index.md")
      create_doc("guide/setup.md")
      create_doc("api/index.md")
      create_doc("api/reference.md")
    end

    context "without tabs configured in auto mode" do
      it "shows all docs in sidebar", :aggregate_failures do
        tree = sidebar.tree

        titles = extract_all_titles(tree)
        expect(titles).to include("Guide", "Api")
      end
    end

    context "with tabs configured on guide section - auto mode ignores tabs" do
      let(:config) do
        create_config(<<~YAML)
          sidebar: auto
          tabs:
            - text: Guide
              href: /guide
            - text: API
              href: /api
        YAML
        Docyard::Config.load(temp_dir)
      end

      it "still shows all docs because auto mode has no tab scoping", :aggregate_failures do
        tree = sidebar.tree

        titles = extract_all_titles(tree)
        expect(titles).to include("Guide", "Api", "Setup", "Reference")
      end
    end
  end

  describe "tab scoping in config mode" do
    let(:current_path) { "/guide/setup" }

    before do
      create_doc("guide/index.md")
      create_doc("guide/setup.md")
      create_doc("api/index.md")
      create_doc("api/reference.md")

      File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
        - guide:
            items:
              - index: { text: Guide Overview }
              - setup: { text: Setup }
        - api:
            items:
              - index: { text: API Overview }
              - reference: { text: Reference }
      YAML
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
  end

  describe "distributed mode" do
    let(:current_path) { "/getting-started/installation" }
    let(:config) do
      create_config(<<~YAML)
        sidebar: distributed
      YAML
      Docyard::Config.load(temp_dir)
    end

    before do
      create_doc("getting-started/index.md")
      create_doc("getting-started/installation.md")
      create_doc("api/index.md")
      create_doc("api/reference.md")

      File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
        - getting-started
        - api
      YAML

      File.write(File.join(docs_dir, "getting-started", "_sidebar.yml"), <<~YAML)
        text: Getting Started
        icon: rocket-launch
        items:
          - index: { text: Overview }
          - installation: { text: Installation }
      YAML

      File.write(File.join(docs_dir, "api", "_sidebar.yml"), <<~YAML)
        text: API Reference
        icon: code
        items:
          - index: { text: Overview }
          - reference: { text: Reference }
      YAML
    end

    it "loads sections from root config", :aggregate_failures do
      tree = sidebar.tree

      expect(tree.length).to eq(2)
      expect(tree[0][:title]).to eq("Getting Started")
      expect(tree[1][:title]).to eq("API Reference")
    end

    it "loads items from section configs", :aggregate_failures do
      tree = sidebar.tree

      expect(tree[0][:children].length).to eq(2)
      expect(tree[0][:children][0][:title]).to eq("Overview")
      expect(tree[0][:children][1][:title]).to eq("Installation")
    end

    it "prefixes paths with section slug", :aggregate_failures do
      tree = sidebar.tree

      expect(tree[0][:children][0][:path]).to eq("/getting-started")
      expect(tree[0][:children][1][:path]).to eq("/getting-started/installation")
      expect(tree[1][:children][1][:path]).to eq("/api/reference")
    end

    it "marks correct item as active", :aggregate_failures do
      tree = sidebar.tree

      expect(tree[0][:children][1][:active]).to be true
      expect(tree[0][:children][0][:active]).to be false
    end
  end

  describe "sidebar cache integration" do
    let(:cache) do
      Docyard::Sidebar::Cache.new(docs_path: docs_dir, config: config)
    end
    let(:sidebar) do
      described_class.new(
        docs_path: docs_dir,
        current_path: current_path,
        config: config,
        sidebar_cache: cache
      )
    end

    before do
      create_doc("getting-started.md")
      File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
        - getting-started
      YAML
      cache.build
    end

    it "uses cached tree when cache is valid", :aggregate_failures do
      tree = sidebar.tree

      expect(tree.length).to eq(1)
      expect(tree[0][:title]).to eq("Getting Started")
    end

    it "marks active items correctly from cache", :aggregate_failures do
      sidebar_at_page = described_class.new(
        docs_path: docs_dir,
        current_path: "/getting-started",
        config: config,
        sidebar_cache: cache
      )

      tree = sidebar_at_page.tree
      expect(tree[0][:active]).to be true
    end
  end

  private

  def extract_all_titles(tree)
    tree.flat_map do |item|
      [item[:title]] + extract_all_titles(item[:children] || [])
    end
  end
end
