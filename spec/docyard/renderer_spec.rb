# frozen_string_literal: true

RSpec.describe Docyard::Renderer do
  let(:renderer) { described_class.new }

  describe "#render" do
    it "wraps content in layout with page title", :aggregate_failures do
      html = renderer.render(content: "<p>Test content</p>", page_title: "Test Page")

      expect(html).to include("<p>Test content</p>")
      expect(html).to include("<title>Test Page</title>")
      expect(html).to include("<!DOCTYPE html>")
    end

    it "uses default title when not provided" do
      html = renderer.render(content: "<p>Content</p>")

      expect(html).to include("<title>Documentation</title>")
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
        expect(html).to include("<title>Test</title>")
      end
    end

    context "without frontmatter" do
      before do
        temp_file.write("# Hello World")
        temp_file.rewind
      end

      it "uses default title" do
        html = renderer.render_file(temp_file.path)

        expect(html).to include("<title>Documentation</title>")
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
