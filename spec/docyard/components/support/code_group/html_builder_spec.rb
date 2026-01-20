# frozen_string_literal: true

RSpec.describe Docyard::Components::Support::CodeGroup::HtmlBuilder do
  let(:group_id) { "test-123" }

  describe "#build" do
    context "with a single block" do
      let(:blocks) do
        [{ label: "JavaScript", lang: "js", content: "<pre>code</pre>", code_text: "const x = 1" }]
      end
      let(:html) { described_class.new(blocks, group_id).build }

      it "creates code group container", :aggregate_failures do
        expect(html).to include('class="docyard-code-group"')
        expect(html).to include('data-code-group="test-123"')
      end

      it "creates tab with correct attributes", :aggregate_failures do
        expect(html).to include('role="tab"')
        expect(html).to include('aria-selected="true"')
        expect(html).to include('aria-controls="cg-panel-test-123-0"')
        expect(html).to include('id="cg-tab-test-123-0"')
      end

      it "creates panel with correct attributes", :aggregate_failures do
        expect(html).to include('role="tabpanel"')
        expect(html).to include('id="cg-panel-test-123-0"')
        expect(html).to include('aria-labelledby="cg-tab-test-123-0"')
        expect(html).to include('aria-hidden="false"')
      end

      it "includes copy button", :aggregate_failures do
        expect(html).to include('class="docyard-code-group__copy"')
        expect(html).to include('aria-label="Copy code to clipboard"')
      end
    end

    context "with multiple blocks" do
      let(:blocks) do
        [
          { label: "JavaScript", lang: "js", content: "<pre>js code</pre>", code_text: "const x = 1" },
          { label: "Python", lang: "py", content: "<pre>py code</pre>", code_text: "x = 1" }
        ]
      end
      let(:html) { described_class.new(blocks, group_id).build }

      it "first tab is selected, others are not", :aggregate_failures do
        expect(html).to match(/aria-selected="true".*id="cg-tab-test-123-0"/m)
        expect(html).to match(/aria-selected="false".*id="cg-tab-test-123-1"/m)
      end

      it "first panel is visible, others are hidden", :aggregate_failures do
        expect(html).to match(/id="cg-panel-test-123-0".*aria-hidden="false"/m)
        expect(html).to match(/id="cg-panel-test-123-1".*aria-hidden="true"/m)
      end

      it "first tab has tabindex 0, others have -1", :aggregate_failures do
        expect(html).to match(/id="cg-tab-test-123-0".*tabindex="0"/m)
        expect(html).to match(/id="cg-tab-test-123-1".*tabindex="-1"/m)
      end
    end

    context "with special characters in labels" do
      let(:blocks) do
        [{ label: "C++ <Templates>", lang: "cpp", content: "<pre>code</pre>", code_text: "" }]
      end
      let(:html) { described_class.new(blocks, group_id).build }

      it "escapes HTML in tab labels", :aggregate_failures do
        expect(html).to include("C++ &lt;Templates&gt;")
        expect(html).not_to include("<Templates>")
      end

      it "escapes HTML in data-label attribute" do
        expect(html).to include('data-label="C++ &lt;Templates&gt;"')
      end
    end

    context "with special characters in code_text" do
      let(:blocks) do
        [{ label: "HTML", lang: "html", content: "<pre>code</pre>", code_text: "<div class=\"test\">content</div>" }]
      end
      let(:html) { described_class.new(blocks, group_id).build }

      it "escapes HTML in data-code attribute" do
        expect(html).to include('data-code="&lt;div class=&quot;test&quot;&gt;content&lt;/div&gt;"')
      end
    end

    context "with newlines in code_text" do
      let(:blocks) do
        [{ label: "Code", lang: "js", content: "<pre>code</pre>", code_text: "line1\nline2" }]
      end
      let(:html) { described_class.new(blocks, group_id).build }

      it "escapes newlines in data-code attribute" do
        expect(html).to include("&#10;")
      end
    end

    context "with nil code_text" do
      let(:blocks) do
        [{ label: "Code", lang: "js", content: "<pre>code</pre>", code_text: nil }]
      end
      let(:html) { described_class.new(blocks, group_id).build }

      it "handles nil code_text gracefully" do
        expect(html).to include('data-code=""')
      end
    end

    context "with empty language" do
      let(:blocks) do
        [{ label: "Plain", lang: "", content: "<pre>code</pre>", code_text: "" }]
      end
      let(:html) { described_class.new(blocks, group_id).build }

      it "does not render icon for empty language" do
        expect(html).not_to include("ph-file")
      end
    end

    context "with nil language" do
      let(:blocks) do
        [{ label: "Plain", lang: nil, content: "<pre>code</pre>", code_text: "" }]
      end
      let(:html) { described_class.new(blocks, group_id).build }

      it "does not render icon for nil language" do
        expect(html).not_to include("ph-file")
      end
    end

    context "with accessibility attributes" do
      let(:blocks) do
        [{ label: "Code", lang: "js", content: "<pre>code</pre>", code_text: "" }]
      end
      let(:html) { described_class.new(blocks, group_id).build }

      it "includes tablist role" do
        expect(html).to include('role="tablist"')
      end

      it "includes aria-label on tablist" do
        expect(html).to include('aria-label="Code examples"')
      end

      it "includes indicator element", :aggregate_failures do
        expect(html).to include('class="docyard-code-group__indicator"')
        expect(html).to include('aria-hidden="true"')
      end

      it "panels have tabindex for keyboard navigation" do
        expect(html).to match(/role="tabpanel"[^>]*tabindex="0"/)
      end
    end
  end
end
