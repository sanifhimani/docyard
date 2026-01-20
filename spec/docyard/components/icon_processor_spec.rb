# frozen_string_literal: true

RSpec.describe Docyard::Components::IconProcessor do
  let(:processor) { described_class.new }

  describe "#postprocess" do
    context "with icon syntax" do
      it "replaces :heart: with rendered icon", :aggregate_failures do
        html = "<p>I :heart: Ruby</p>"
        result = processor.postprocess(html)

        expect(result).to include('<i class="ph ph-heart" aria-hidden="true"></i>')
        expect(result).not_to include(":heart:")
      end

      it "replaces :check: with rendered icon", :aggregate_failures do
        html = "<p>:check: Complete</p>"
        result = processor.postprocess(html)

        expect(result).to include("ph-check")
        expect(result).not_to include(":check:")
      end

      it "handles single-letter icons like :x:", :aggregate_failures do
        html = "<p>:x: Error</p>"
        result = processor.postprocess(html)

        expect(result).to include("ph-x")
        expect(result).not_to include(":x:")
      end

      it "handles hyphenated icon names", :aggregate_failures do
        html = "<p>Click :arrow-right: to continue</p>"
        result = processor.postprocess(html)

        expect(result).to include("ph-arrow-right")
        expect(result).not_to include(":arrow-right:")
      end

      it "handles multiple icons in same text", :aggregate_failures do
        html = "<p>:check: Done :heart: Love :arrow-right: Next</p>"
        result = processor.postprocess(html)

        expect(result).to include("ph-check")
        expect(result).to include("ph-heart")
        expect(result).to include("ph-arrow-right")
      end

      it "renders icon with accessibility attributes" do
        html = "<p>:heart:</p>"
        result = processor.postprocess(html)

        expect(result).to include('aria-hidden="true"')
      end

      it "renders any icon name via CDN", :aggregate_failures do
        html = "<p>:acorn: :air-traffic-control: :airplane-taxiing:</p>"
        result = processor.postprocess(html)

        expect(result).to include("ph-acorn")
        expect(result).to include("ph-air-traffic-control")
        expect(result).to include("ph-airplane-taxiing")
      end
    end

    context "with weighted icon syntax" do
      it "renders :heart:bold: with bold weight class", :aggregate_failures do
        html = "<p>:heart:bold:</p>"
        result = processor.postprocess(html)

        expect(result).to include('<i class="ph-bold ph-heart"')
        expect(result).not_to include(":bold:")
      end

      it "renders :heart:fill: with fill weight class", :aggregate_failures do
        html = "<p>:heart:fill:</p>"
        result = processor.postprocess(html)

        expect(result).to include('<i class="ph-fill ph-heart"')
        expect(result).not_to include(":fill:")
      end

      it "renders :heart:light: with light weight class", :aggregate_failures do
        html = "<p>:heart:light:</p>"
        result = processor.postprocess(html)

        expect(result).to include('<i class="ph-light ph-heart"')
        expect(result).not_to include(":light:")
      end

      it "renders :heart:thin: with thin weight class", :aggregate_failures do
        html = "<p>:heart:thin:</p>"
        result = processor.postprocess(html)

        expect(result).to include('<i class="ph-thin ph-heart"')
        expect(result).not_to include(":thin:")
      end

      it "renders :heart:duotone: with duotone weight class", :aggregate_failures do
        html = "<p>:heart:duotone:</p>"
        result = processor.postprocess(html)

        expect(result).to include('<i class="ph-duotone ph-heart"')
        expect(result).not_to include(":duotone:")
      end

      it "falls back to regular weight for invalid weight" do
        html = "<p>:heart:invalid:</p>"
        result = processor.postprocess(html)

        expect(result).to include('<i class="ph ph-heart"')
      end
    end

    context "with code blocks" do
      it "does not process icons inside <code> tags", :aggregate_failures do
        html = "<p>Use <code>:heart:</code> for icons</p>"
        result = processor.postprocess(html)

        expect(result).to include("<code>:heart:</code>")
        expect(result).not_to include("ph-heart")
      end

      it "does not process icons inside <pre> tags", :aggregate_failures do
        html = "<pre>:check: Task complete</pre>"
        result = processor.postprocess(html)

        expect(result).to include("<pre>:check: Task complete</pre>")
        expect(result).not_to include("ph-")
      end

      it "does not process icons inside syntax highlighted code blocks", :aggregate_failures do
        html = '<pre class="highlight"><code>:heart: :rocket:</code></pre>'
        result = processor.postprocess(html)

        expect(result).to include(":heart:")
        expect(result).to include(":rocket:")
        expect(result).not_to include("ph-")
      end

      it "processes icons outside code blocks but not inside", :aggregate_failures do
        html = "<p>:check: Done <code>:warning:</code> :arrow-right:</p>"
        result = processor.postprocess(html)

        expect(result).to include("ph-check")
        expect(result).to include("ph-arrow-right")
        expect(result).to include("<code>:warning:</code>")
      end
    end

    context "with mixed content" do
      it "handles icons in headings", :aggregate_failures do
        html = "<h1>:rocket-launch: Getting Started</h1>"
        result = processor.postprocess(html)

        expect(result).to include("ph-rocket-launch")
        expect(result).to include("Getting Started")
      end

      it "handles icons in lists", :aggregate_failures do
        html = "<ul><li>:check: Item 1</li><li>:x: Item 2</li></ul>"
        result = processor.postprocess(html)

        expect(result).to include("ph-check")
        expect(result).to include("ph-x")
      end

      it "handles icons in bold text", :aggregate_failures do
        html = "<p><strong>:warning: Important</strong></p>"
        result = processor.postprocess(html)

        expect(result).to include("ph-warning")
        expect(result).to include("<strong>")
      end

      it "handles icons in links", :aggregate_failures do
        html = '<p><a href="/docs">:arrow-right: Read more</a></p>'
        result = processor.postprocess(html)

        expect(result).to include("ph-arrow-right")
        expect(result).to include('<a href="/docs">')
      end
    end

    context "with empty or nil content" do
      it "handles empty string" do
        result = processor.postprocess("")

        expect(result).to eq("")
      end

      it "handles plain text without icons" do
        html = "<p>No icons here</p>"
        result = processor.postprocess(html)

        expect(result).to eq(html)
      end
    end

    context "with edge cases" do
      it "does not match incomplete syntax" do
        html = "<p>:heart incomplete</p>"
        result = processor.postprocess(html)

        expect(result).to eq(html)
      end

      it "does not match with spaces" do
        html = "<p>: heart :</p>"
        result = processor.postprocess(html)

        expect(result).to eq(html)
      end

      it "handles consecutive icons", :aggregate_failures do
        html = "<p>:check::heart::rocket-launch:</p>"
        result = processor.postprocess(html)

        expect(result).to include("ph-check")
        expect(result).to include("ph-heart")
        expect(result).to include("ph-rocket-launch")
      end
    end
  end
end
