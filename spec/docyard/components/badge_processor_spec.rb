# frozen_string_literal: true

RSpec.describe Docyard::Components::BadgeProcessor do
  let(:processor) { described_class.new }

  describe "#postprocess" do
    context "with basic badge syntax" do
      it "converts badge with text only", :aggregate_failures do
        html = "<p>Status: :badge[Active]</p>"
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-badge docyard-badge--default"')
        expect(result).to include(">Active</span>")
      end

      it "converts badge with type attribute", :aggregate_failures do
        html = '<p>:badge[Stable]{type="success"}</p>'
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-badge docyard-badge--success"')
        expect(result).to include(">Stable</span>")
      end

      it "supports warning type" do
        html = '<p>:badge[Beta]{type="warning"}</p>'
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-badge docyard-badge--warning"')
      end

      it "supports danger type" do
        html = '<p>:badge[Deprecated]{type="danger"}</p>'
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-badge docyard-badge--danger"')
      end

      it "defaults to default type for invalid types" do
        html = '<p>:badge[Test]{type="invalid"}</p>'
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-badge docyard-badge--default"')
      end
    end

    context "with badges in headings" do
      it "converts badge within h1", :aggregate_failures do
        html = '<h1 id="title">Installation :badge[New]{type="success"}</h1>'
        result = processor.postprocess(html)

        expect(result).to include("<h1")
        expect(result).to include('class="docyard-badge docyard-badge--success"')
        expect(result).to include(">New</span>")
      end

      it "converts badge within h2", :aggregate_failures do
        html = '<h2 id="config">Configuration :badge[Beta]{type="warning"}</h2>'
        result = processor.postprocess(html)

        expect(result).to include("<h2")
        expect(result).to include('class="docyard-badge docyard-badge--warning"')
      end

      it "converts badge within h3", :aggregate_failures do
        html = '<h3 id="old">Legacy API :badge[Deprecated]{type="danger"}</h3>'
        result = processor.postprocess(html)

        expect(result).to include("<h3")
        expect(result).to include('class="docyard-badge docyard-badge--danger"')
      end
    end

    context "with multiple badges" do
      it "converts all badges in content", :aggregate_failures do
        html = '<p>:badge[v1.0]{type="success"} and :badge[v2.0]{type="warning"}</p>'
        result = processor.postprocess(html)

        expect(result.scan("docyard-badge").length).to eq(4)
        expect(result).to include("docyard-badge--success")
        expect(result).to include("docyard-badge--warning")
      end
    end

    context "with code blocks" do
      it "does not process badges inside inline code", :aggregate_failures do
        html = '<p>Use <code>:badge[text]{type="success"}</code> syntax</p>'
        result = processor.postprocess(html)

        expect(result).not_to include("docyard-badge")
        expect(result).to include(':badge[text]{type="success"}')
      end

      it "does not process badges inside pre blocks" do
        html = '<pre><code>:badge[text]{type="success"}</code></pre>'
        result = processor.postprocess(html)

        expect(result).not_to include("docyard-badge")
      end

      it "processes badges outside code blocks", :aggregate_failures do
        html = '<p>:badge[Real]{type="success"}</p><code>:badge[Fake]</code>'
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-badge docyard-badge--success"')
        expect(result).to include("<code>:badge[Fake]</code>")
      end
    end

    context "with empty attributes" do
      it "handles empty attributes block" do
        html = "<p>:badge[Text]{}</p>"
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-badge docyard-badge--default"')
      end

      it "handles badge with no attributes", :aggregate_failures do
        html = "<p>:badge[Plain]</p>"
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-badge docyard-badge--default"')
        expect(result).to include(">Plain</span>")
      end
    end

    context "with surrounding content" do
      it "keeps text before and after badge", :aggregate_failures do
        html = "<p>This is :badge[Important]{type=\"warning\"} information.</p>"
        result = processor.postprocess(html)

        expect(result).to include("This is")
        expect(result).to include("information.")
        expect(result).to include("docyard-badge--warning")
      end
    end

    context "with single quotes in attributes" do
      it "supports single-quoted attribute values" do
        html = "<p>:badge[Test]{type='success'}</p>"
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-badge docyard-badge--success"')
      end
    end

    context "with smart/curly quotes in attributes" do
      it "supports curly double quotes from Kramdown" do
        html = "<p>:badge[Test]{type=\u201Csuccess\u201D}</p>"
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-badge docyard-badge--success"')
      end
    end
  end
end
