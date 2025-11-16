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
        expect(html).to include('<div class="nav-section">')
      end

      it "renders file link", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include('<a href="/getting-started"')
        expect(html).to include(">Getting Started</span>")
      end
    end

    context "with directory and children" do
      let(:tree) do
        [{
          title: "Guide",
          path: nil,
          active: false,
          type: :directory,
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

      it "renders nested lists with button group", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include('<div class="nav-section-title">GUIDE</div>')
        expect(html).to include('<a href="/guide/setup"')
        expect(html).to include(">Setup</span>")
      end
    end

    context "with empty directory" do
      let(:tree) do
        [{
          title: "Reference",
          path: nil,
          active: false,
          type: :directory,
          children: []
        }]
      end

      it "does not render empty sections", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).not_to include("REFERENCE")
      end
    end

    context "with custom site title" do
      let(:renderer) { described_class.new(site_title: "Custom Title") }
      let(:tree) do
        [
          { title: "Custom Title", path: "/", active: false, type: :file, children: [] },
          { title: "Test", path: "/test", active: false, type: :file, children: [] }
        ]
      end

      it "filters out site title from navigation", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include('<a href="/test"')
        expect(html.scan("Custom Title").length).to eq(0)
      end
    end

    context "with default site title" do
      let(:renderer) { described_class.new }
      let(:tree) do
        [
          { title: "Documentation", path: "/", active: false, type: :file, children: [] },
          { title: "Test", path: "/test", active: false, type: :file, children: [] }
        ]
      end

      it "filters out default Documentation title from navigation", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include('<a href="/test"')
        expect(html).not_to include(">Documentation</a>")
      end
    end
  end
end
