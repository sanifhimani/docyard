# frozen_string_literal: true

RSpec.describe Docyard::Components::CardsProcessor do
  let(:processor) { described_class.new }

  describe "#preprocess" do
    context "with basic cards syntax" do
      it "converts cards block with card elements", :aggregate_failures do
        markdown = <<~MD
          :::cards
          ::card{title="First Card" icon="star" href="/first/"}
          First card content.
          ::
          ::card{title="Second Card" icon="code" href="/second/"}
          Second card content.
          ::
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-cards"')
        expect(result).to include('class="docyard-card"')
        expect(result).to include('class="docyard-card__title">First Card</h3>')
        expect(result).to include('class="docyard-card__title">Second Card</h3>')
      end

      it "renders card as link when href provided", :aggregate_failures do
        markdown = <<~MD
          :::cards
          ::card{title="Linked Card" href="/path/"}
          Content here.
          ::
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('<a href="/path/" class="docyard-card">')
        expect(result).to include("</a>")
      end

      it "renders card as div when no href provided", :aggregate_failures do
        markdown = <<~MD
          :::cards
          ::card{title="Static Card"}
          Content here.
          ::
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('<div class="docyard-card">')
        expect(result).to include("</div>")
        expect(result).not_to include("<a")
      end

      it "renders icon when provided", :aggregate_failures do
        markdown = <<~MD
          :::cards
          ::card{title="With Icon" icon="rocket-launch"}
          Content.
          ::
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-card__icon"')
        expect(result).to include("<svg")
      end

      it "omits icon section when not provided" do
        markdown = <<~MD
          :::cards
          ::card{title="No Icon"}
          Content.
          ::
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).not_to include('class="docyard-card__icon"')
      end
    end

    context "with markdown content" do
      it "processes bold and italic text", :aggregate_failures do
        markdown = <<~MD
          :::cards
          ::card{title="Formatting"}
          This has **bold** and *italic* text.
          ::
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("<strong>bold</strong>")
        expect(result).to include("<em>italic</em>")
      end

      it "processes inline code" do
        markdown = <<~MD
          :::cards
          ::card{title="Code"}
          Run `bundle install` to start.
          ::
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("<code>bundle install</code>")
      end
    end

    context "with multiple cards" do
      it "renders all cards in grid", :aggregate_failures do
        markdown = ":::cards\n::card{title=\"One\"}\nA\n::\n::card{title=\"Two\"}\nB\n::\n:::"

        result = processor.preprocess(markdown)

        expect(result.scan('class="docyard-card"').length).to eq(2)
        expect(result).to include(">One</h3>")
        expect(result).to include(">Two</h3>")
      end
    end

    context "with edge cases" do
      it "uses default title when not provided" do
        markdown = <<~MD
          :::cards
          ::card{}
          Content.
          ::
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include(">Card</h3>")
      end

      it "handles card with no content", :aggregate_failures do
        markdown = <<~MD
          :::cards
          ::card{title="Empty Card"}
          ::
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-card__title">Empty Card</h3>')
        expect(result).not_to include('class="docyard-card__body"')
      end

      it "does not match incomplete syntax" do
        markdown = ":::cards\n::card{title=\"Test\"}\nNo closing tag"
        result = processor.preprocess(markdown)

        expect(result).to eq(markdown)
      end

      it "preserves content outside cards", :aggregate_failures do
        markdown = <<~MD
          Before cards.

          :::cards
          ::card{title="Test"}
          Content.
          ::
          :::

          After cards.
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("Before cards.")
        expect(result).to include("After cards.")
      end

      it "handles empty cards block" do
        markdown = ":::cards\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-cards"')
      end
    end
  end
end
