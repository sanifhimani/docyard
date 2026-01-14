# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::CustomAnchorProcessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#postprocess" do
    context "with custom anchor ID" do
      it "replaces auto-generated ID with custom ID" do
        html = '<h2 id="configuration-options">Configuration Options {#config}</h2>'
        result = processor.postprocess(html)

        expect(result).to eq('<h2 id="config">Configuration Options</h2>')
      end

      it "removes the custom ID syntax from heading text", :aggregate_failures do
        html = '<h2 id="my-heading">My Heading {#custom-id}</h2>'
        result = processor.postprocess(html)

        expect(result).not_to include("{#custom-id}")
        expect(result).to include("My Heading")
      end
    end

    context "with different heading levels" do
      it "works with h1" do
        html = '<h1 id="title">Title {#main-title}</h1>'
        result = processor.postprocess(html)

        expect(result).to eq('<h1 id="main-title">Title</h1>')
      end

      it "works with h3" do
        html = '<h3 id="subsection">Subsection {#sub}</h3>'
        result = processor.postprocess(html)

        expect(result).to eq('<h3 id="sub">Subsection</h3>')
      end

      it "works with h6" do
        html = '<h6 id="deep">Deep Heading {#deep-link}</h6>'
        result = processor.postprocess(html)

        expect(result).to eq('<h6 id="deep-link">Deep Heading</h6>')
      end
    end

    context "with headings without custom IDs" do
      it "leaves standard headings unchanged" do
        html = '<h2 id="normal-heading">Normal Heading</h2>'
        result = processor.postprocess(html)

        expect(result).to eq('<h2 id="normal-heading">Normal Heading</h2>')
      end
    end

    context "with multiple headings" do
      it "processes only headings with custom IDs", :aggregate_failures do
        html = <<~HTML
          <h2 id="intro">Introduction {#intro-section}</h2>
          <h2 id="normal">Normal Section</h2>
          <h3 id="details">Details {#details-anchor}</h3>
        HTML

        result = processor.postprocess(html)

        expect(result).to include('id="intro-section"')
        expect(result).to include('id="normal"')
        expect(result).to include('id="details-anchor"')
        expect(result).not_to include("{#")
      end
    end

    context "with special characters in custom IDs" do
      it "supports hyphens in custom IDs" do
        html = '<h2 id="auto">Title {#my-custom-id}</h2>'
        result = processor.postprocess(html)

        expect(result).to include('id="my-custom-id"')
      end

      it "supports underscores in custom IDs" do
        html = '<h2 id="auto">Title {#my_custom_id}</h2>'
        result = processor.postprocess(html)

        expect(result).to include('id="my_custom_id"')
      end

      it "supports numbers in custom IDs" do
        html = '<h2 id="auto">Title {#section-123}</h2>'
        result = processor.postprocess(html)

        expect(result).to include('id="section-123"')
      end
    end

    context "with whitespace variations" do
      it "handles space before custom ID" do
        html = '<h2 id="auto">Title {#custom}</h2>'
        result = processor.postprocess(html)

        expect(result).to eq('<h2 id="custom">Title</h2>')
      end

      it "handles multiple spaces before custom ID" do
        html = '<h2 id="auto">Title   {#custom}</h2>'
        result = processor.postprocess(html)

        expect(result).to eq('<h2 id="custom">Title</h2>')
      end
    end

    context "with headings containing inline elements" do
      it "preserves inline code in heading", :aggregate_failures do
        html = '<h2 id="auto">Using <code>config</code> {#config-usage}</h2>'
        result = processor.postprocess(html)

        expect(result).to include("<code>config</code>")
        expect(result).to include('id="config-usage"')
      end

      it "preserves links in heading", :aggregate_failures do
        html = '<h2 id="auto">See <a href="/link">docs</a> {#see-docs}</h2>'
        result = processor.postprocess(html)

        expect(result).to include('<a href="/link">docs</a>')
        expect(result).to include('id="see-docs"')
      end
    end

    context "with heading without existing ID" do
      it "adds custom ID to heading without ID attribute" do
        html = "<h2>Title {#new-id}</h2>"
        result = processor.postprocess(html)

        expect(result).to eq('<h2 id="new-id">Title</h2>')
      end
    end
  end
end
