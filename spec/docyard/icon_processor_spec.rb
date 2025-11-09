# frozen_string_literal: true

RSpec.describe Docyard::IconProcessor do
  describe ".process" do
    context "with icon syntax" do
      it "replaces :heart: with rendered icon", :aggregate_failures do
        html = "<p>I :heart: Ruby</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-heart")
        expect(result).not_to include(":heart:")
      end

      it "replaces :check: with rendered icon", :aggregate_failures do
        html = "<p>:check: Complete</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-check")
        expect(result).not_to include(":check:")
      end

      it "handles single-letter icons like :x:", :aggregate_failures do
        html = "<p>:x: Error</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-x")
        expect(result).not_to include(":x:")
      end

      it "handles hyphenated icon names", :aggregate_failures do
        html = "<p>Click :arrow-right: to continue</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-arrow-right")
        expect(result).not_to include(":arrow-right:")
      end

      it "handles multiple icons in same text", :aggregate_failures do
        html = "<p>:check: Done :heart: Love :arrow-right: Next</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-check")
        expect(result).to include("docyard-icon-heart")
        expect(result).to include("docyard-icon-arrow-right")
      end
    end

    context "with weighted icon syntax" do
      it "renders :heart:bold: with bold weight", :aggregate_failures do
        html = "<p>:heart:bold:</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-heart")
        expect(result).not_to include(":bold:")
      end

      it "renders :heart:fill: with fill weight", :aggregate_failures do
        html = "<p>:heart:fill:</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-heart")
        expect(result).not_to include(":fill:")
      end

      it "renders :heart:light: with light weight", :aggregate_failures do
        html = "<p>:heart:light:</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-heart")
        expect(result).not_to include(":light:")
      end

      it "renders :heart:thin: with thin weight", :aggregate_failures do
        html = "<p>:heart:thin:</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-heart")
        expect(result).not_to include(":thin:")
      end

      it "renders :heart:duotone: with duotone weight", :aggregate_failures do
        html = "<p>:heart:duotone:</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-heart")
        expect(result).not_to include(":duotone:")
      end
    end

    context "with unknown icons" do
      it "leaves unknown icon syntax as-is" do
        html = "<p>:unknown-icon: stays</p>"
        result = described_class.process(html)

        expect(result).to eq(html)
      end

      it "leaves unknown weight as-is" do
        html = "<p>:heart:invalid: stays</p>"
        result = described_class.process(html)

        expect(result).to include(":heart:invalid:")
      end
    end

    context "with code blocks" do
      it "does not process icons inside <code> tags", :aggregate_failures do
        html = "<p>Use <code>:heart:</code> for icons</p>"
        result = described_class.process(html)

        expect(result).to include("<code>:heart:</code>")
        expect(result).not_to include("docyard-icon-heart")
      end

      it "does not process icons inside <pre> tags", :aggregate_failures do
        html = "<pre>:check: Task complete</pre>"
        result = described_class.process(html)

        expect(result).to include("<pre>:check: Task complete</pre>")
        expect(result).not_to include("docyard-icon")
      end

      it "does not process icons inside syntax highlighted code blocks", :aggregate_failures do
        html = '<pre class="highlight"><code>:heart: :rocket:</code></pre>'
        result = described_class.process(html)

        expect(result).to include(":heart:")
        expect(result).to include(":rocket:")
        expect(result).not_to include("docyard-icon")
      end

      it "processes icons outside code blocks but not inside", :aggregate_failures do
        html = "<p>:check: Done <code>:warning:</code> :arrow-right:</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-check")
        expect(result).to include("docyard-icon-arrow-right")
        expect(result).to include("<code>:warning:</code>")
        expect(result).not_to include("docyard-icon-warning")
      end
    end

    context "with mixed content" do
      it "handles icons in headings", :aggregate_failures do
        html = "<h1>:rocket-launch: Getting Started</h1>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-rocket-launch")
        expect(result).to include("Getting Started")
      end

      it "handles icons in lists", :aggregate_failures do
        html = "<ul><li>:check: Item 1</li><li>:x: Item 2</li></ul>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-check")
        expect(result).to include("docyard-icon-x")
      end

      it "handles icons in bold text", :aggregate_failures do
        html = "<p><strong>:warning: Important</strong></p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-warning")
        expect(result).to include("<strong>")
      end

      it "handles icons in links", :aggregate_failures do
        html = '<p><a href="/docs">:arrow-right: Read more</a></p>'
        result = described_class.process(html)

        expect(result).to include("docyard-icon-arrow-right")
        expect(result).to include('<a href="/docs">')
      end
    end

    context "with empty or nil content" do
      it "handles empty string" do
        result = described_class.process("")

        expect(result).to eq("")
      end

      it "handles plain text without icons" do
        html = "<p>No icons here</p>"
        result = described_class.process(html)

        expect(result).to eq(html)
      end
    end

    context "with edge cases" do
      it "does not match incomplete syntax" do
        html = "<p>:heart incomplete</p>"
        result = described_class.process(html)

        expect(result).to eq(html)
      end

      it "does not match with spaces" do
        html = "<p>: heart :</p>"
        result = described_class.process(html)

        expect(result).to eq(html)
      end

      it "handles consecutive icons", :aggregate_failures do
        html = "<p>:check::heart::rocket-launch:</p>"
        result = described_class.process(html)

        expect(result).to include("docyard-icon-check")
        expect(result).to include("docyard-icon-heart")
        expect(result).to include("docyard-icon-rocket-launch")
      end
    end
  end
end
