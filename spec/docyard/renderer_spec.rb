# frozen_string_literal: true

RSpec.describe Docyard::Renderer do
  let(:renderer) { described_class.new }

  describe "#render" do
    it "wraps content in layout with page title", :aggregate_failures do
      html = renderer.render(content: "<p>Test content</p>", page_title: "Test Page")

      expect(html).to include("<p>Test content</p>")
      expect(html).to include("<title>Test Page | Documentation</title>")
      expect(html).to include("<!DOCTYPE html>")
    end

    it "uses default title when not provided" do
      html = renderer.render(content: "<p>Content</p>")

      expect(html).to include("<title>Documentation | Documentation</title>")
    end

    it "renders with logo when custom logo is set", :aggregate_failures do
      html = renderer.render(content: "<p>Content</p>", branding: { logo: "logo.svg", has_custom_logo: true })

      expect(html).to include('src="/logo.svg"')
      expect(html).to include("site-logo-light")
    end

    it "renders with dark mode logo when provided", :aggregate_failures do
      html = renderer.render(
        content: "<p>Content</p>",
        branding: {
          logo: "logo.svg",
          logo_dark: "logo-dark.svg",
          has_custom_logo: true
        }
      )

      expect(html).to include('src="/logo-dark.svg"')
      expect(html).to include("site-logo-dark")
    end

    it "renders with favicon when provided" do
      html = renderer.render(content: "<p>Content</p>", branding: { favicon: "favicon.ico" })

      expect(html).to include('href="/favicon.ico"')
    end

    it "renders title only when no custom logo is set", :aggregate_failures do
      html = renderer.render(content: "<p>Content</p>", branding: { has_custom_logo: false })

      expect(html).to include("header-title")
      expect(html).not_to include("site-logo")
    end

    it "renders logo only when custom logo is set", :aggregate_failures do
      html = renderer.render(content: "<p>Content</p>", branding: { has_custom_logo: true, logo: "custom-logo.svg" })

      expect(html).to include("site-logo")
      expect(html).to include('src="/custom-logo.svg"')
      expect(html).not_to include("header-title")
    end

    it "renders with navigation components", :aggregate_failures do
      navigation = {
        sidebar_html: "<nav>Sidebar</nav>",
        prev_next_html: "<footer>Prev/Next</footer>",
        toc: [{ text: "Heading", id: "heading", level: 2, children: [] }]
      }
      html = renderer.render(content: "<p>Content</p>", navigation: navigation)

      expect(html).to include("<nav>Sidebar</nav>", "<footer>Prev/Next</footer>", "Heading")
    end
  end

  describe "#render_partial" do
    it "renders a partial template", :aggregate_failures do
      html = renderer.render_partial("_theme_toggle")

      expect(html).to include("theme-toggle")
      expect(html).to include("theme-toggle-sun")
    end

    it "renders a partial with locals", :aggregate_failures do
      html = renderer.render_partial("_icon", name: "rocket-launch", icon_data: '<path d="test"/>')

      expect(html).to include("svg")
      expect(html).to include("docyard-icon")
      expect(html).to include("rocket-launch")
    end
  end

  describe "#render_not_found" do
    it "renders 404 page", :aggregate_failures do
      html = renderer.render_not_found

      expect(html).to include("404")
      expect(html).to include("Page Not Found")
    end
  end

  describe "#render_file" do
    let(:temp_file) { Tempfile.new(["test", ".md"]) }

    after { temp_file.unlink }

    context "with frontmatter" do
      before do
        temp_file.write("---\ntitle: Test\n---\n# Hello")
        temp_file.rewind
      end

      it "renders markdown with title from frontmatter", :aggregate_failures do
        html = renderer.render_file(temp_file.path)

        expect(html).to include("<h1")
        expect(html).to include("Hello")
        expect(html).to include("<title>Test | Documentation</title>")
      end
    end

    context "without frontmatter" do
      before do
        temp_file.write("# Hello World")
        temp_file.rewind
      end

      it "uses default title" do
        html = renderer.render_file(temp_file.path)

        expect(html).to include("<title>Documentation | Documentation</title>")
      end
    end

    context "with markdown links" do
      before do
        temp_file.write("# Page\n\n[Link to page](page.md)\n\n[Nested](guide/setup.md)")
        temp_file.rewind
      end

      it "strips .md extensions from links (VitePress-style)", :aggregate_failures do
        html = renderer.render_file(temp_file.path)

        expect(html).to include('href="page"')
        expect(html).to include('href="guide/setup"')
        expect(html).not_to include(".md")
      end
    end
  end
end
