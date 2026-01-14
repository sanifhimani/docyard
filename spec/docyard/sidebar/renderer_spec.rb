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
          section: true,
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

      it "renders section header by default", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include('<h5 class="nav-section-title">Guide</h5>')
        expect(html).to include('<a href="/guide/setup"')
        expect(html).to include(">Setup</span>")
      end
    end

    context "with collapsible group" do
      let(:tree) do
        [{
          title: "Resources",
          path: nil,
          active: false,
          type: :directory,
          section: false,
          collapsed: false,
          children: [
            {
              title: "FAQ",
              path: "/resources/faq",
              active: false,
              type: :file,
              children: []
            }
          ]
        }]
      end

      it "renders collapsible group when section is false", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include('class="nav-group-header')
        expect(html).to include(">Resources</span>")
        expect(html).to include('<a href="/resources/faq"')
        expect(html).to include(">FAQ</span>")
      end

      it "renders data-default-collapsed attribute" do
        html = renderer.render(tree)

        expect(html).to include('data-default-collapsed="false"')
      end
    end

    context "with collapsed group" do
      let(:tree) do
        [{
          title: "Advanced",
          path: nil,
          active: false,
          type: :directory,
          section: false,
          collapsed: true,
          children: [
            {
              title: "Config",
              path: "/advanced/config",
              active: false,
              type: :file,
              children: []
            }
          ]
        }]
      end

      it "renders data-default-collapsed as true when collapsed", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include('data-default-collapsed="true"')
        expect(html).to include('aria-expanded="false"')
      end
    end

    context "with section icon" do
      let(:tree) do
        [{
          title: "API",
          path: nil,
          active: false,
          type: :directory,
          section: true,
          icon: "code",
          children: [
            {
              title: "Reference",
              path: "/api/reference",
              active: false,
              type: :file,
              children: []
            }
          ]
        }]
      end

      it "renders section header with icon", :aggregate_failures do
        html = renderer.render(tree)

        expect(html).to include('<h5 class="nav-section-title">')
        expect(html).to include("nav-section-icon")
        expect(html).to include("API</h5>")
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
