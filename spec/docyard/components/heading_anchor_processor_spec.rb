# frozen_string_literal: true

RSpec.describe Docyard::Components::HeadingAnchorProcessor do
  let(:processor) { described_class.new }

  describe "#postprocess" do
    context "with headings" do
      it "adds anchor link to h2 heading", :aggregate_failures do
        html = '<h2 id="test-heading">Test Heading</h2>'

        result = processor.postprocess(html)

        expect(result).to include('href="#test-heading"')
        expect(result).to include('class="heading-anchor"')
        expect(result).to include('aria-label="Link to this section"')
        expect(result).to include('data-heading-id="test-heading"')
        expect(result).to include(">Test Heading<a")
      end

      it "adds anchor link to h3 heading", :aggregate_failures do
        html = '<h3 id="subsection">Subsection</h3>'

        result = processor.postprocess(html)

        expect(result).to include('href="#subsection"')
        expect(result).to include('class="heading-anchor"')
      end

      it "adds anchor link to h4 heading", :aggregate_failures do
        html = '<h4 id="details">Details</h4>'

        result = processor.postprocess(html)

        expect(result).to include('href="#details"')
        expect(result).to include('class="heading-anchor"')
      end

      it "adds anchor link to h5 heading", :aggregate_failures do
        html = '<h5 id="note">Note</h5>'

        result = processor.postprocess(html)

        expect(result).to include('href="#note"')
        expect(result).to include('class="heading-anchor"')
      end

      it "adds anchor link to h6 heading", :aggregate_failures do
        html = '<h6 id="footnote">Footnote</h6>'

        result = processor.postprocess(html)

        expect(result).to include('href="#footnote"')
        expect(result).to include('class="heading-anchor"')
      end

      it "handles multiple headings", :aggregate_failures do
        html = <<~HTML
          <h2 id="first">First</h2>
          <h3 id="second">Second</h3>
          <h4 id="third">Third</h4>
        HTML

        result = processor.postprocess(html)

        expect(result).to include('href="#first"')
        expect(result).to include('href="#second"')
        expect(result).to include('href="#third"')
        expect(result.scan('class="heading-anchor"').length).to eq(3)
      end

      it "preserves heading content with nested HTML", :aggregate_failures do
        html = '<h2 id="test">Test <strong>Bold</strong> Heading</h2>'

        result = processor.postprocess(html)

        expect(result).to include("Test <strong>Bold</strong> Heading")
        expect(result).to include('class="heading-anchor"')
      end

      it "handles headings with multiple words in ID", :aggregate_failures do
        html = '<h2 id="getting-started-guide">Getting Started Guide</h2>'

        result = processor.postprocess(html)

        expect(result).to include('href="#getting-started-guide"')
        expect(result).to include('data-heading-id="getting-started-guide"')
      end

      it "places anchor link at the end of heading content" do
        html = '<h2 id="test">Test Heading</h2>'

        result = processor.postprocess(html)

        expect(result).to match(/Test Heading<a[^>]*class="heading-anchor"/)
      end
    end

    context "without headings" do
      it "returns HTML unchanged" do
        html = "<p>Just some content without headings</p>"

        result = processor.postprocess(html)

        expect(result).to eq(html)
      end
    end

    context "with headings without IDs" do
      it "ignores headings without IDs", :aggregate_failures do
        html = "<h2>No ID Heading</h2>"

        result = processor.postprocess(html)

        expect(result).to eq(html)
        expect(result).not_to include('class="heading-anchor"')
      end

      it "only adds anchors to headings with IDs", :aggregate_failures do
        html = <<~HTML
          <h2>No ID</h2>
          <h2 id="with-id">With ID</h2>
        HTML

        result = processor.postprocess(html)

        expect(result.scan('class="heading-anchor"').length).to eq(1)
        expect(result).to include('href="#with-id"')
      end
    end

    context "with multiline heading content" do
      it "handles headings split across lines", :aggregate_failures do
        html = <<~HTML.chomp
          <h2 id="test">Test
          Heading</h2>
        HTML

        result = processor.postprocess(html)

        expect(result).to include('class="heading-anchor"')
        expect(result).to include('href="#test"')
      end
    end
  end
end
