# frozen_string_literal: true

RSpec.describe Docyard::BreadcrumbBuilder do
  describe "#items" do
    context "with flat navigation" do
      let(:sidebar_tree) do
        [
          { title: "First", path: "/first", type: :file, children: [] },
          { title: "Second", path: "/second", type: :file, children: [] },
          { title: "Third", path: "/third", type: :file, children: [] }
        ]
      end

      it "returns single item for current page", :aggregate_failures do
        builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/second")
        items = builder.items

        expect(items.length).to eq(1)
        expect(items.first.title).to eq("Second")
        expect(items.first.current).to be true
      end
    end

    context "with nested navigation" do
      let(:sidebar_tree) do
        [
          {
            title: "Getting Started", path: "/getting-started", type: :folder, children: [
              { title: "Introduction", path: "/getting-started/intro", type: :file, children: [] },
              { title: "Installation", path: "/getting-started/install", type: :file, children: [] }
            ]
          },
          { title: "API", path: "/api", type: :file, children: [] }
        ]
      end

      it "returns parent and current for nested page", :aggregate_failures do
        builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/getting-started/install")
        items = builder.items

        expect(items.length).to eq(2)
        expect(items.first.title).to eq("Getting Started")
        expect(items.first.current).to be false
        expect(items.last.title).to eq("Installation")
        expect(items.last.current).to be true
      end

      it "returns links for parent items", :aggregate_failures do
        builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/getting-started/install")
        items = builder.items

        expect(items.first.href).to eq("/getting-started")
        expect(items.last.href).to eq("/getting-started/install")
      end
    end

    context "with deeply nested navigation (3 levels)" do
      let(:sidebar_tree) do
        [
          {
            title: "Guides", path: "/guides", type: :folder, children: [
              {
                title: "Advanced", path: "/guides/advanced", type: :folder, children: [
                  { title: "Configuration", path: "/guides/advanced/config", type: :file, children: [] }
                ]
              }
            ]
          }
        ]
      end

      it "returns all three levels", :aggregate_failures do
        builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/guides/advanced/config")
        items = builder.items

        expect(items.length).to eq(3)
        expect(items.map(&:title)).to eq(%w[Guides Advanced Configuration])
      end
    end

    context "with deeply nested navigation (4+ levels)" do
      let(:sidebar_tree) do
        [
          {
            title: "Documentation", path: "/docs", type: :folder, children: [
              {
                title: "Guides", path: "/docs/guides", type: :folder, children: [
                  {
                    title: "Advanced", path: "/docs/guides/advanced", type: :folder, children: [
                      { title: "Configuration", path: "/docs/guides/advanced/config", type: :file, children: [] }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      end

      it "truncates to 3 items with ellipsis", :aggregate_failures do
        builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/docs/guides/advanced/config")
        items = builder.items

        expect(items.length).to eq(3)
        expect(items.first.title).to eq("...")
        expect(items[1].title).to eq("Advanced")
        expect(items.last.title).to eq("Configuration")
      end

      it "marks as truncated" do
        builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/docs/guides/advanced/config")

        expect(builder.truncated?).to be true
      end
    end
  end

  describe "#should_show?" do
    let(:sidebar_tree) do
      [
        { title: "First", path: "/first", type: :file, children: [] }
      ]
    end

    it "returns true for non-root pages with items" do
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/first")

      expect(builder.should_show?).to be true
    end

    it "returns false for root page" do
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/")

      expect(builder.should_show?).to be false
    end

    it "returns false for empty sidebar tree" do
      builder = described_class.new(sidebar_tree: [], current_path: "/first")

      expect(builder.should_show?).to be false
    end
  end

  describe "#truncated?" do
    context "with 3 or fewer levels" do
      let(:sidebar_tree) do
        [
          {
            title: "Guides", path: "/guides", type: :folder, children: [
              { title: "Intro", path: "/guides/intro", type: :file, children: [] }
            ]
          }
        ]
      end

      it "returns false" do
        builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/guides/intro")

        expect(builder.truncated?).to be false
      end
    end

    context "with more than 3 levels" do
      let(:sidebar_tree) do
        [
          {
            title: "A", path: "/a", type: :folder, children: [
              {
                title: "B", path: "/a/b", type: :folder, children: [
                  {
                    title: "C", path: "/a/b/c", type: :folder, children: [
                      { title: "D", path: "/a/b/c/d", type: :file, children: [] }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      end

      it "returns true" do
        builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/a/b/c/d")

        expect(builder.truncated?).to be true
      end
    end
  end

  describe "title truncation" do
    let(:sidebar_tree) do
      [
        {
          title: "This is an extremely long title that should be truncated for display",
          path: "/long-title",
          type: :file,
          children: []
        }
      ]
    end

    it "truncates titles longer than 30 characters", :aggregate_failures do
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/long-title")
      items = builder.items

      expect(items.first.title.length).to be <= 30
      expect(items.first.title).to end_with("...")
    end
  end

  describe "path normalization" do
    let(:sidebar_tree) do
      [
        { title: "First", path: "/first/", type: :file, children: [] }
      ]
    end

    it "handles trailing slashes in sidebar paths" do
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/first")

      expect(builder.items.first.title).to eq("First")
    end

    it "handles trailing slashes in current path" do
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/first/")

      expect(builder.items.first.title).to eq("First")
    end
  end

  describe "edge cases" do
    it "handles nil sidebar tree", :aggregate_failures do
      builder = described_class.new(sidebar_tree: nil, current_path: "/test")

      expect(builder.items).to eq([])
      expect(builder.should_show?).to be false
    end

    it "handles empty current path" do
      sidebar_tree = [{ title: "Home", path: "/", type: :file, children: [] }]
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "")

      expect(builder.should_show?).to be false
    end

    it "handles page not in sidebar" do
      sidebar_tree = [{ title: "First", path: "/first", type: :file, children: [] }]
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/unknown")

      expect(builder.items).to eq([])
    end
  end

  describe "section headers with nil path" do
    let(:sidebar_tree) do
      [
        {
          title: "Getting Started",
          path: nil,
          type: :folder,
          children: [
            { title: "Overview", path: "/getting-started/overview", type: :file, children: [] },
            { title: "Installation", path: "/getting-started/installation", type: :file, children: [] }
          ]
        }
      ]
    end

    it "links section to first navigable child", :aggregate_failures do
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/getting-started/installation")
      items = builder.items

      expect(items.length).to eq(2)
      expect(items.first.title).to eq("Getting Started")
      expect(items.first.href).to eq("/getting-started/overview")
    end

    it "handles section with empty path string", :aggregate_failures do
      tree = [
        {
          title: "Docs",
          path: "",
          type: :folder,
          children: [
            { title: "Intro", path: "/docs/intro", type: :file, children: [] }
          ]
        }
      ]
      builder = described_class.new(sidebar_tree: tree, current_path: "/docs/intro")
      items = builder.items

      expect(items.length).to eq(2)
      expect(items.first.href).to eq("/docs/intro")
    end
  end

  describe "section with index page" do
    let(:sidebar_tree) do
      [
        {
          title: "Components",
          path: "/components",
          type: :folder,
          children: [
            { title: "Buttons", path: "/components/buttons", type: :file, children: [] },
            { title: "Forms", path: "/components/forms", type: :file, children: [] }
          ]
        }
      ]
    end

    it "uses section path when index exists", :aggregate_failures do
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/components/forms")
      items = builder.items

      expect(items.length).to eq(2)
      expect(items.first.title).to eq("Components")
      expect(items.first.href).to eq("/components")
    end
  end

  describe "nested sections without index" do
    let(:sidebar_tree) do
      [
        {
          title: "Write Content",
          path: "/write-content",
          type: :folder,
          children: [
            {
              title: "Components",
              path: nil,
              type: :folder,
              children: [
                { title: "Code Blocks", path: "/write-content/components/code-blocks", type: :file, children: [] }
              ]
            }
          ]
        }
      ]
    end

    it "links nested section without index to first child", :aggregate_failures do
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/write-content/components/code-blocks")
      items = builder.items

      expect(items.length).to eq(3)
      expect(items[0].title).to eq("Write Content")
      expect(items[0].href).to eq("/write-content")
      expect(items[1].title).to eq("Components")
      expect(items[1].href).to eq("/write-content/components/code-blocks")
      expect(items[2].title).to eq("Code Blocks")
      expect(items[2].current).to be true
    end
  end

  describe "section with first child as index page" do
    let(:sidebar_tree) do
      [
        {
          title: "Get Started",
          path: nil,
          type: :folder,
          children: [
            { title: "Introduction", path: "/getting-started", type: :file, children: [] },
            { title: "Quickstart", path: "/getting-started/quickstart", type: :file, children: [] }
          ]
        }
      ]
    end

    it "shows section in breadcrumbs when first child is index page", :aggregate_failures do
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/getting-started/quickstart")
      items = builder.items

      expect(items.length).to eq(2)
      expect(items[0].title).to eq("Get Started")
      expect(items[0].href).to eq("/getting-started")
      expect(items[1].title).to eq("Quickstart")
      expect(items[1].current).to be true
    end

    it "shows section and index page when viewing index", :aggregate_failures do
      builder = described_class.new(sidebar_tree: sidebar_tree, current_path: "/getting-started")
      items = builder.items

      expect(items.length).to eq(2)
      expect(items[0].title).to eq("Get Started")
      expect(items[0].href).to eq("/getting-started")
      expect(items[1].title).to eq("Introduction")
      expect(items[1].current).to be true
    end
  end
end
