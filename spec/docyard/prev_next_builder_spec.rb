# frozen_string_literal: true

RSpec.describe Docyard::PrevNextBuilder do
  let(:config) { {} }

  describe "#flat_links" do
    context "with nested sidebar structure" do
      let(:sidebar_tree) do
        [
          {
            title: "Getting Started",
            path: nil,
            type: :directory,
            children: [
              { title: "Installation", path: "/installation", type: :file, children: [] },
              { title: "Quick Start", path: "/quick-start", type: :file, children: [] }
            ]
          },
          {
            title: "Guides",
            path: nil,
            type: :directory,
            children: [
              { title: "Configuration", path: "/guides/configuration", type: :file, children: [] }
            ]
          }
        ]
      end
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/installation",
          frontmatter: {},
          config: config
        )
      end

      it "flattens nested structure and excludes directories", :aggregate_failures do
        flat = builder.send(:flat_links)

        expect(flat.length).to eq(3)
        expect(flat[0][:title]).to eq("Installation")
        expect(flat[1][:title]).to eq("Quick Start")
        expect(flat[2][:title]).to eq("Configuration")
        expect(flat.none? { |link| link[:title] == "Getting Started" }).to be true
      end
    end

    context "with external links" do
      let(:sidebar_tree) do
        [
          { title: "Local Page", path: "/local", type: :file, children: [] },
          { title: "External Link", path: "https://example.com", type: :file, children: [] },
          { title: "Another Page", path: "/another", type: :file, children: [] }
        ]
      end
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/local",
          frontmatter: {},
          config: config
        )
      end

      it "excludes external links from flattened array", :aggregate_failures do
        flat = builder.send(:flat_links)

        expect(flat.length).to eq(2)
        expect(flat[0][:title]).to eq("Local Page")
        expect(flat[1][:title]).to eq("Another Page")
        expect(flat.none? { |link| link[:title] == "External Link" }).to be true
      end
    end

    context "with hash anchors" do
      let(:sidebar_tree) do
        [
          { title: "Page One", path: "/page#section1", type: :file, children: [] },
          { title: "Page One Alt", path: "/page#section2", type: :file, children: [] },
          { title: "Page Two", path: "/page-two", type: :file, children: [] }
        ]
      end
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/page",
          frontmatter: {},
          config: config
        )
      end

      it "deduplicates paths by stripping hash anchors", :aggregate_failures do
        flat = builder.send(:flat_links)

        expect(flat.length).to eq(2)
        expect(flat[0][:path]).to eq("/page#section1")
        expect(flat[1][:path]).to eq("/page-two")
      end
    end
  end

  describe "#current_page_index" do
    let(:sidebar_tree) do
      [
        { title: "First", path: "/first", type: :file, children: [] },
        { title: "Second", path: "/second", type: :file, children: [] },
        { title: "Third", path: "/third", type: :file, children: [] }
      ]
    end

    context "when page is in sidebar" do
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/second",
          frontmatter: {},
          config: config
        )
      end

      it "returns correct index" do
        expect(builder.send(:current_page_index)).to eq(1)
      end
    end

    context "when page is not in sidebar" do
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/nonexistent",
          frontmatter: {},
          config: config
        )
      end

      it "returns nil" do
        expect(builder.send(:current_page_index)).to be_nil
      end
    end
  end

  describe "#prev_next_links" do
    let(:sidebar_tree) do
      [
        { title: "First", path: "/first", type: :file, children: [] },
        { title: "Second", path: "/second", type: :file, children: [] },
        { title: "Third", path: "/third", type: :file, children: [] }
      ]
    end

    context "when on first page" do
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/first",
          frontmatter: {},
          config: config
        )
      end

      it "has no previous link", :aggregate_failures do
        links = builder.prev_next_links

        expect(links[:prev]).to be_nil
        expect(links[:next][:title]).to eq("Second")
      end
    end

    context "when on middle page" do
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/second",
          frontmatter: {},
          config: config
        )
      end

      it "has both prev and next links", :aggregate_failures do
        links = builder.prev_next_links

        expect(links[:prev][:title]).to eq("First")
        expect(links[:next][:title]).to eq("Third")
      end
    end

    context "when on last page" do
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/third",
          frontmatter: {},
          config: config
        )
      end

      it "has no next link", :aggregate_failures do
        links = builder.prev_next_links

        expect(links[:prev][:title]).to eq("Second")
        expect(links[:next]).to be_nil
      end
    end

    context "when disabled globally" do
      let(:config) { { enabled: false } }
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/second",
          frontmatter: {},
          config: config
        )
      end

      it "returns nil" do
        expect(builder.prev_next_links).to be_nil
      end
    end

    context "when both disabled in frontmatter" do
      let(:frontmatter) { { "prev" => false, "next" => false } }
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/second",
          frontmatter: frontmatter,
          config: config
        )
      end

      it "returns nil" do
        expect(builder.prev_next_links).to be_nil
      end
    end

    context "with frontmatter string override" do
      let(:frontmatter) { { "prev" => "First" } }
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/second",
          frontmatter: frontmatter,
          config: config
        )
      end

      it "finds link by text match", :aggregate_failures do
        links = builder.prev_next_links

        expect(links[:prev][:title]).to eq("First")
        expect(links[:prev][:path]).to eq("/first")
      end
    end

    context "with frontmatter object override" do
      let(:frontmatter) do
        {
          "next" => {
            "text" => "Custom Next",
            "link" => "/custom"
          }
        }
      end
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/first",
          frontmatter: frontmatter,
          config: config
        )
      end

      it "uses custom text and link", :aggregate_failures do
        links = builder.prev_next_links

        expect(links[:next][:title]).to eq("Custom Next")
        expect(links[:next][:path]).to eq("/custom")
      end
    end

    context "with prev disabled but next enabled" do
      let(:frontmatter) { { "prev" => false } }
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/second",
          frontmatter: frontmatter,
          config: config
        )
      end

      it "shows only next link", :aggregate_failures do
        links = builder.prev_next_links

        expect(links[:prev]).to be_nil
        expect(links[:next][:title]).to eq("Third")
      end
    end
  end

  describe "#to_html" do
    let(:sidebar_tree) do
      [
        { title: "First", path: "/first", type: :file, children: [] },
        { title: "Second", path: "/second", type: :file, children: [] }
      ]
    end

    context "when prev/next exists" do
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/first",
          frontmatter: {},
          config: config
        )
      end

      it "returns HTML with navigation", :aggregate_failures do
        html = builder.to_html

        expect(html).to include("doc-footer")
        expect(html).to include("pager")
      end
    end

    context "when both prev and next are nil" do
      let(:builder) do
        described_class.new(
          sidebar_tree: [],
          current_path: "/first",
          frontmatter: {},
          config: config
        )
      end

      it "returns empty string" do
        expect(builder.to_html).to eq("")
      end
    end

    context "with custom labels" do
      let(:config) { { prev_text: "← Back", next_text: "Forward →" } }
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/first",
          frontmatter: {},
          config: config
        )
      end

      it "uses custom text labels", :aggregate_failures do
        html = builder.to_html

        expect(html).to include("Forward →")
      end
    end
  end
end
