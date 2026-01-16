# frozen_string_literal: true

RSpec.describe Docyard::Components::StepsProcessor do
  let(:processor) { described_class.new }

  describe "#preprocess" do
    context "with basic steps syntax" do
      it "converts steps block with headings", :aggregate_failures do
        markdown = <<~MD
          :::steps
          ### First Step
          Do this first.

          ### Second Step
          Then do this.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-steps"')
        expect(result).to include('class="docyard-step"')
        expect(result).to include('class="docyard-step__number">1</span>')
        expect(result).to include('class="docyard-step__number">2</span>')
        expect(result).to include('class="docyard-step__title">First Step</h3>')
        expect(result).to include('class="docyard-step__title">Second Step</h3>')
      end

      it "renders step content", :aggregate_failures do
        markdown = <<~MD
          :::steps
          ### Install
          Run the install command.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("Run the install command")
        expect(result).to include('class="docyard-step__body"')
      end

      it "marks last step correctly", :aggregate_failures do
        markdown = <<~MD
          :::steps
          ### Step One
          Content one.

          ### Step Two
          Content two.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-step docyard-step--last"')
        expect(result.scan("docyard-step--last").length).to eq(1)
      end

      it "includes connector between steps" do
        markdown = <<~MD
          :::steps
          ### First
          Content.

          ### Second
          More content.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-step__connector"')
      end
    end

    context "with markdown content" do
      it "processes bold and italic text", :aggregate_failures do
        markdown = <<~MD
          :::steps
          ### Formatting
          This has **bold** and *italic* text.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("<strong>bold</strong>")
        expect(result).to include("<em>italic</em>")
      end

      it "processes inline code" do
        markdown = <<~MD
          :::steps
          ### Code Example
          Run `bundle install` to install dependencies.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("<code>bundle install</code>")
      end

      it "processes code blocks", :aggregate_failures do
        markdown = <<~MD
          :::steps
          ### Install
          ```bash
          gem install docyard
          ```
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("highlight")
        expect(result).to include("gem")
        expect(result).to include("docyard")
      end

      it "processes lists", :aggregate_failures do
        markdown = <<~MD
          :::steps
          ### Requirements
          - Ruby 3.2+
          - Bundler
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("<ul>")
        expect(result).to include("<li>Ruby 3.2+</li>")
        expect(result).to include("<li>Bundler</li>")
      end

      it "processes links" do
        markdown = <<~MD
          :::steps
          ### Learn More
          Visit the [documentation](https://example.com).
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('<a href="https://example.com">documentation</a>')
      end
    end

    context "with multiple steps" do
      it "numbers steps sequentially", :aggregate_failures do
        markdown = <<~MD
          :::steps
          ### One
          First.

          ### Two
          Second.

          ### Three
          Third.

          ### Four
          Fourth.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include(">1</span>")
        expect(result).to include(">2</span>")
        expect(result).to include(">3</span>")
        expect(result).to include(">4</span>")
      end

      it "only last step has --last modifier" do
        markdown = <<~MD
          :::steps
          ### A
          Content.

          ### B
          Content.

          ### C
          Content.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result.scan("docyard-step--last").length).to eq(1)
      end
    end

    context "with edge cases" do
      it "handles steps with no content", :aggregate_failures do
        markdown = <<~MD
          :::steps
          ### Empty Step
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-step__title">Empty Step</h3>')
        expect(result).not_to include('class="docyard-step__body"')
      end

      it "does not match incomplete syntax" do
        markdown = ":::steps\n### Step\nNo closing tag"
        result = processor.preprocess(markdown)

        expect(result).to eq(markdown)
      end

      it "preserves content outside steps", :aggregate_failures do
        markdown = <<~MD
          Before steps.

          :::steps
          ### Step
          Content.
          :::

          After steps.
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("Before steps.")
        expect(result).to include("After steps.")
      end

      it "handles empty steps block" do
        markdown = ":::steps\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-steps"')
      end
    end

    context "with code blocks" do
      it "does not process steps syntax inside code blocks", :aggregate_failures do
        markdown = <<~MD
          :::steps
          ### Real Step
          Real content
          :::

          ```markdown
          :::steps
          ### Example Step
          Example syntax
          :::
          ```
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-steps"')
        expect(result.scan("docyard-steps").count).to eq(1)
        expect(result).to include(":::steps\n### Example Step")
      end
    end
  end
end
