# frozen_string_literal: true

RSpec.describe Docyard::Sidebar::Renderer do
  let(:renderer) { described_class.new(site_title: "My Docs") }

  describe "#render" do
    context "with empty tree" do
      it "returns empty string" do
        expect(renderer.render([])).to eq("")
      end
    end

    context "with single file" do
      let(:tree) do
        [{
          title: "Getting Started",
          path: "/getting-started",
          active: true,
          type: :file,
          children: []
        }]
      end

      it "renders basic nav structure", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include("<nav>")
        expect(html).to include("<ul>")
        expect(html).to include("<li>")
        expect(html).to include('<a href="/">My Docs</a>')
      end

      it "renders file link" do
        html = renderer.render(tree)

        expect(html).to include('<a href="/getting-started">Getting Started</a>')
      end
    end

    context "with directory and children" do
      let(:tree) do
        [{
          title: "Guide",
          path: "/guide",
          active: false,
          type: :directory,
          collapsible: true,
          collapsed: false,
          children: [
            {
              title: "Setup",
              path: "/guide/setup",
              active: true,
              type: :file,
              children: []
            }
          ]
        }]
      end

      it "renders nested lists", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include('<a href="/guide">Guide</a>')
        expect(html).to include('<a href="/guide/setup">Setup</a>')
      end
    end

    context "with non-clickable directory" do
      let(:tree) do
        [{
          title: "Reference",
          path: nil,
          active: false,
          type: :directory,
          collapsible: true,
          collapsed: false,
          children: []
        }]
      end

      it "renders span instead of link", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include("<span>Reference</span>")
        expect(html).not_to include('href="/reference"')
      end
    end

    context "with custom site title" do
      let(:renderer) { described_class.new(site_title: "Custom Title") }
      let(:tree) { [{ title: "Test", path: "/test", active: false, type: :file, children: [] }] }

      it "uses custom site title" do
        html = renderer.render(tree)

        expect(html).to include('<a href="/">Custom Title</a>')
      end
    end

    context "with default site title" do
      let(:renderer) { described_class.new }
      let(:tree) { [{ title: "Test", path: "/test", active: false, type: :file, children: [] }] }

      it "uses default Documentation title" do
        html = renderer.render(tree)

        expect(html).to include('<a href="/">Documentation</a>')
      end
    end
  end
end
