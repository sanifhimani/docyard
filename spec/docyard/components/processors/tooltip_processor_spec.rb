# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::TooltipProcessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with basic tooltip" do
      it "converts tooltip syntax to span element", :aggregate_failures do
        content = "The :tooltip[API]{description=\"Application Programming Interface\"} handles requests."
        result = processor.preprocess(content)

        expect(result).to include('<span class="docyard-tooltip"')
        expect(result).to include(">API</span>")
      end

      it "includes description in data attribute" do
        content = "The :tooltip[API]{description=\"Application Programming Interface\"} handles requests."
        result = processor.preprocess(content)

        expect(result).to include('data-description="Application Programming Interface"')
      end
    end

    context "with link attribute" do
      it "includes link in data attribute", :aggregate_failures do
        content = ':tooltip[API]{description="An interface" link="/api"}'
        result = processor.preprocess(content)

        expect(result).to include('data-link="/api"')
        expect(result).to include('data-link-text="Learn more"')
      end

      it "uses custom link text when provided" do
        content = ':tooltip[API]{description="An interface" link="/api" link_text="Read the docs"}'
        result = processor.preprocess(content)

        expect(result).to include('data-link-text="Read the docs"')
      end
    end

    context "with multiple tooltips" do
      it "processes all tooltips", :aggregate_failures do
        content = "The :tooltip[API]{description=\"Interface\"} and :tooltip[SDK]{description=\"Kit\"} work together."
        result = processor.preprocess(content)

        expect(result).to include(">API</span>")
        expect(result).to include(">SDK</span>")
        expect(result).to include('data-description="Interface"')
        expect(result).to include('data-description="Kit"')
      end
    end

    context "with no tooltips" do
      it "returns content unchanged" do
        content = "Just regular text without any tooltips."
        result = processor.preprocess(content)

        expect(result).to eq(content)
      end
    end

    context "with special characters in description" do
      it "escapes HTML in description", :aggregate_failures do
        content = ":tooltip[Code]{description=\"Use <script> & 'quotes'\"}"
        result = processor.preprocess(content)

        expect(result).to include("&lt;script&gt;")
        expect(result).to include("&amp;")
        expect(result).to include("'quotes'")
      end
    end

    context "with long descriptions" do
      it "handles multi-word descriptions" do
        description = "Application Programming Interface: a set of protocols."
        content = ":tooltip[API]{description=\"#{description}\"}"
        result = processor.preprocess(content)

        expect(result).to include("data-description=\"#{description}\"")
      end
    end

    context "with tooltip in different positions" do
      it "works at start of line" do
        content = ":tooltip[API]{description=\"Interface\"} is important."
        result = processor.preprocess(content)

        expect(result).to start_with('<span class="docyard-tooltip"')
      end

      it "works at end of line" do
        content = "Learn about the :tooltip[API]{description=\"Interface\"}"
        result = processor.preprocess(content)

        expect(result).to end_with(">API</span>")
      end

      it "works in middle of sentence", :aggregate_failures do
        content = "The :tooltip[API]{description=\"Interface\"} handles requests."
        result = processor.preprocess(content)

        expect(result).to include("The <span")
        expect(result).to include("</span> handles")
      end
    end

    context "with missing description" do
      it "uses empty description" do
        content = ':tooltip[API]{link="/api"}'
        result = processor.preprocess(content)

        expect(result).to include('data-description=""')
      end
    end

    context "with external links" do
      it "handles full URLs" do
        content = ':tooltip[GitHub]{description="Code hosting" link="https://github.com"}'
        result = processor.preprocess(content)

        expect(result).to include('data-link="https://github.com"')
      end
    end
  end
end
