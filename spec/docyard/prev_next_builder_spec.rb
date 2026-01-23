# frozen_string_literal: true

RSpec.describe Docyard::PrevNextBuilder do
  let(:config) { {} }

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

    context "when on page before directory with index" do
      let(:sidebar_tree) do
        [
          { title: "First", path: "/first", type: :file, children: [] },
          { title: "Section", path: "/section", type: :directory, has_index: true, children: [
            { title: "Nested", path: "/section/nested", type: :file, children: [] }
          ] },
          { title: "Last", path: "/last", type: :file, children: [] }
        ]
      end

      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/first",
          frontmatter: {},
          config: config
        )
      end

      it "links to directory index as next", :aggregate_failures do
        links = builder.prev_next_links

        expect(links[:next][:title]).to eq("Section")
        expect(links[:next][:path]).to eq("/section")
      end
    end

    context "when on directory index page" do
      let(:sidebar_tree) do
        [
          { title: "First", path: "/first", type: :file, children: [] },
          { title: "Section", path: "/section", type: :directory, has_index: true, children: [
            { title: "Nested", path: "/section/nested", type: :file, children: [] }
          ] },
          { title: "Last", path: "/last", type: :file, children: [] }
        ]
      end

      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/section",
          frontmatter: {},
          config: config
        )
      end

      it "has prev and next links", :aggregate_failures do
        links = builder.prev_next_links

        expect(links[:prev][:title]).to eq("First")
        expect(links[:next][:title]).to eq("Nested")
      end
    end

    context "with directory items without index pages" do
      let(:sidebar_tree) do
        [
          { title: "First", path: "/first", type: :file, children: [] },
          { title: "Section", path: "/section", type: :directory, has_index: false, children: [
            { title: "Nested", path: "/section/nested", type: :file, children: [] }
          ] },
          { title: "Last", path: "/last", type: :file, children: [] }
        ]
      end

      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/first",
          frontmatter: {},
          config: config
        )
      end

      it "skips directory and links to first nested item", :aggregate_failures do
        links = builder.prev_next_links

        expect(links[:next][:title]).to eq("Nested")
        expect(links[:next][:path]).to eq("/section/nested")
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

    context "with base URL" do
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/first",
          frontmatter: {},
          config: config,
          base_url: "/my-docs/"
        )
      end

      it "prepends base URL to navigation links" do
        html = builder.to_html

        expect(html).to include('href="/my-docs/second"')
      end
    end

    context "with root base URL" do
      let(:builder) do
        described_class.new(
          sidebar_tree: sidebar_tree,
          current_path: "/first",
          frontmatter: {},
          config: config,
          base_url: "/"
        )
      end

      it "does not modify links" do
        html = builder.to_html

        expect(html).to include('href="/second"')
      end
    end
  end
end
