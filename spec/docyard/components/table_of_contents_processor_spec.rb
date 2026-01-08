# frozen_string_literal: true

RSpec.describe Docyard::Components::TableOfContentsProcessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#postprocess" do
    context "with headings" do
      it "extracts h2, h3, and h4 headings", :aggregate_failures do
        html = <<~HTML
          <h2 id="getting-started">Getting Started</h2>
          <h3 id="installation">Installation</h3>
        HTML

        processor.postprocess(html)
        toc = context[:toc]

        expect(toc).to be_an(Array)
        expect(toc.length).to eq(1)
      end

      it "captures heading metadata correctly", :aggregate_failures do
        html = '<h2 id="getting-started">Getting Started</h2>'
        processor.postprocess(html)
        toc = context[:toc]

        expect(toc[0][:level]).to eq(2)
        expect(toc[0][:id]).to eq("getting-started")
        expect(toc[0][:text]).to eq("Getting Started")
      end

      it "nests child headings under parents", :aggregate_failures do
        html = '<h2 id="parent">Parent</h2><h3 id="child">Child</h3>'
        processor.postprocess(html)
        toc = context[:toc]

        expect(toc[0][:children].length).to eq(1)
        expect(toc[0][:children][0][:id]).to eq("child")
      end

      it "returns HTML unchanged" do
        html = <<~HTML
          <h2 id="test">Test</h2>
          <p>Content</p>
        HTML

        result = processor.postprocess(html)

        expect(result).to eq(html)
      end

      it "builds three-level nested hierarchy", :aggregate_failures do
        html = '<h2 id="h2">H2</h2><h3 id="h3">H3</h3><h4 id="h4">H4</h4>'
        processor.postprocess(html)
        toc = context[:toc]

        expect(toc[0][:children][0][:children].length).to eq(1)
      end

      it "handles multiple sections at same level" do
        html = '<h2 id="s1">S1</h2><h3 id="s1a">S1a</h3><h3 id="s1b">S1b</h3>'
        processor.postprocess(html)
        toc = context[:toc]

        expect(toc[0][:children].length).to eq(2)
      end

      it "preserves text across all levels", :aggregate_failures do
        html = '<h2 id="s1">Section 1</h2><h3 id="s1-1">Sub 1.1</h3><h4 id="s1-1-1">Sub 1.1.1</h4>'
        processor.postprocess(html)
        toc = context[:toc]

        expect(toc[0][:text]).to eq("Section 1")
        expect(toc[0][:children][0][:text]).to eq("Sub 1.1")
        expect(toc[0][:children][0][:children][0][:text]).to eq("Sub 1.1.1")
      end

      it "strips heading anchor links from text" do
        html = <<~HTML
          <h2 id="test">Test Heading<a href="#test" class="heading-anchor">#</a></h2>
        HTML

        processor.postprocess(html)
        toc = context[:toc]

        expect(toc[0][:text]).to eq("Test Heading")
      end

      it "strips HTML tags from heading text" do
        html = <<~HTML
          <h2 id="test">Test <strong>Bold</strong> Heading</h2>
        HTML

        processor.postprocess(html)
        toc = context[:toc]

        expect(toc[0][:text]).to eq("Test Bold Heading")
      end

      it "ignores h1, h5, and h6 headings", :aggregate_failures do
        html = <<~HTML
          <h1 id="title">Title</h1>
          <h2 id="section">Section</h2>
          <h5 id="note">Note</h5>
          <h6 id="footer">Footer</h6>
        HTML

        processor.postprocess(html)
        toc = context[:toc]

        expect(toc.length).to eq(1)
        expect(toc[0][:text]).to eq("Section")
      end
    end

    context "without headings" do
      it "returns empty array" do
        html = "<p>Just some content</p>"

        processor.postprocess(html)
        toc = context[:toc]

        expect(toc).to eq([])
      end
    end

    context "with headings without IDs" do
      it "ignores headings without IDs", :aggregate_failures do
        html = <<~HTML
          <h2>No ID Heading</h2>
          <h2 id="with-id">With ID</h2>
        HTML

        processor.postprocess(html)
        toc = context[:toc]

        expect(toc.length).to eq(1)
        expect(toc[0][:text]).to eq("With ID")
      end
    end
  end
end
