# frozen_string_literal: true

RSpec.describe Docyard::Components::AccordionProcessor do
  let(:processor) { described_class.new }

  describe "#preprocess" do
    context "with basic accordion syntax" do
      it "converts details block with title attribute", :aggregate_failures do
        markdown = <<~MD
          :::details{title="Advanced Configuration"}
          This is the hidden content.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-accordion"')
        expect(result).to include('class="docyard-accordion__summary"')
        expect(result).to include('class="docyard-accordion__title">Advanced Configuration</span>')
        expect(result).to include("This is the hidden content")
      end

      it "uses default title when not specified", :aggregate_failures do
        markdown = <<~MD
          :::details
          Hidden content here.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-accordion__title">Details</span>')
        expect(result).to include("Hidden content here")
      end

      it "renders as HTML details element", :aggregate_failures do
        markdown = ":::details{title=\"Test\"}\nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("<details")
        expect(result).to include("<summary")
        expect(result).to include("</details>")
      end

      it "includes caret icon for expand indicator", :aggregate_failures do
        markdown = ":::details{title=\"Test\"}\nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("<svg")
        expect(result).to include('class="docyard-accordion__icon"')
      end
    end

    context "with open attribute" do
      it "renders details element with open attribute when specified", :aggregate_failures do
        markdown = <<~MD
          :::details{title="Open by default" open}
          This content is visible by default.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("<details class=\"docyard-accordion\" open>")
        expect(result).to include("This content is visible by default")
      end

      it "renders without open attribute by default", :aggregate_failures do
        markdown = ":::details{title=\"Closed\"}\nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('<details class="docyard-accordion">')
        expect(result).not_to match(/<details[^>]*open/)
      end
    end

    context "with markdown content" do
      it "processes markdown formatting inside accordion", :aggregate_failures do
        markdown = <<~MD
          :::details{title="Formatting Test"}
          This has **bold** and *italic* text.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("<strong>bold</strong>")
        expect(result).to include("<em>italic</em>")
      end

      it "processes inline code inside accordion" do
        markdown = ":::details{title=\"Code\"}\nUse `bundle install` to install.\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("<code>bundle install</code>")
      end

      it "processes code blocks inside accordion", :aggregate_failures do
        markdown = <<~MD
          :::details{title="Code Example"}
          ```ruby
          puts "hello"
          ```
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("highlight")
        expect(result).to include("puts")
        expect(result).to include("hello")
      end

      it "processes lists inside accordion", :aggregate_failures do
        markdown = <<~MD
          :::details{title="List Example"}
          - Item one
          - Item two
          - Item three
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("<ul>")
        expect(result).to include("<li>Item one</li>")
        expect(result).to include("<li>Item two</li>")
      end

      it "processes multi-paragraph content", :aggregate_failures do
        markdown = <<~MD
          :::details{title="Multi-paragraph"}
          First paragraph.

          Second paragraph.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("First paragraph")
        expect(result).to include("Second paragraph")
      end
    end

    context "with multiple accordions" do
      it "converts multiple accordions in same document", :aggregate_failures do
        markdown = <<~MD
          :::details{title="First"}
          First content
          :::

          :::details{title="Second"}
          Second content
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result.scan('class="docyard-accordion"').length).to eq(2)
        expect(result).to include("First content")
        expect(result).to include("Second content")
      end

      it "handles consecutive accordions", :aggregate_failures do
        markdown = <<~MD
          :::details{title="One"}
          Content one
          :::
          :::details{title="Two"}
          Content two
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include(">One</span>")
        expect(result).to include(">Two</span>")
      end
    end

    context "with edge cases" do
      it "handles empty content", :aggregate_failures do
        markdown = ":::details{title=\"Empty\"}\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("docyard-accordion")
        expect(result).to include('class="docyard-accordion__content"')
      end

      it "does not match incomplete syntax" do
        markdown = ":::details{title=\"No close\"}\nContent without closing"
        result = processor.preprocess(markdown)

        expect(result).to eq(markdown)
      end

      it "preserves content outside accordions", :aggregate_failures do
        markdown = <<~MD
          Regular paragraph

          :::details{title="Accordion"}
          Hidden content
          :::

          Another paragraph
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("Regular paragraph")
        expect(result).to include("Another paragraph")
      end

      it "handles title with special characters" do
        markdown = ":::details{title=\"What's the deal?\"}\nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("What's the deal?")
      end
    end
  end
end
