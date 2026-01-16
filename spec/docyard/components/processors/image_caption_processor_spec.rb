# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::ImageCaptionProcessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with captioned image" do
      it "wraps image in figure element", :aggregate_failures do
        content = '![Alt text](image.png){caption="Figure 1: Description"}'
        result = processor.preprocess(content)

        expect(result).to include('<figure class="docyard-figure"')
        expect(result).to include("</figure>")
      end

      it "includes the image with src and alt", :aggregate_failures do
        content = '![Alt text](image.png){caption="Caption"}'
        result = processor.preprocess(content)

        expect(result).to include('src="image.png"')
        expect(result).to include('alt="Alt text"')
      end

      it "includes figcaption with caption text" do
        content = '![Alt](img.png){caption="Figure 1: Architecture diagram"}'
        result = processor.preprocess(content)

        expect(result).to include("<figcaption>Figure 1: Architecture diagram</figcaption>")
      end
    end

    context "with width attribute" do
      it "adds width to image", :aggregate_failures do
        content = '![Alt](image.png){width="300"}'
        result = processor.preprocess(content)

        expect(result).to include('width="300"')
        expect(result).not_to include("<figure")
      end

      it "combines width with caption", :aggregate_failures do
        content = '![Alt](image.png){caption="Description" width="500"}'
        result = processor.preprocess(content)

        expect(result).to include('width="500"')
        expect(result).to include("<figure")
        expect(result).to include("<figcaption>Description</figcaption>")
      end
    end

    context "with height attribute" do
      it "adds height to image" do
        content = '![Alt](image.png){height="200"}'
        result = processor.preprocess(content)

        expect(result).to include('height="200"')
      end

      it "combines width and height", :aggregate_failures do
        content = '![Alt](image.png){width="300" height="200"}'
        result = processor.preprocess(content)

        expect(result).to include('width="300"')
        expect(result).to include('height="200"')
      end
    end

    context "with nozoom attribute" do
      it "adds data-no-zoom attribute" do
        content = "![Alt](image.png){nozoom}"
        result = processor.preprocess(content)

        expect(result).to include("data-no-zoom")
      end

      it "combines nozoom with caption", :aggregate_failures do
        content = '![Alt](image.png){caption="Description" nozoom}'
        result = processor.preprocess(content)

        expect(result).to include("data-no-zoom")
        expect(result).to include("<figure")
        expect(result).to include("<figcaption>Description</figcaption>")
      end

      it "combines all attributes", :aggregate_failures do
        content = '![Alt](image.png){caption="Diagram" width="400" nozoom}'
        result = processor.preprocess(content)

        expect(result).to include('width="400"')
        expect(result).to include("data-no-zoom")
        expect(result).to include("<figcaption>Diagram</figcaption>")
      end
    end

    context "with various image paths" do
      it "handles relative paths" do
        content = '![Diagram](./images/arch.png){caption="Architecture"}'
        result = processor.preprocess(content)

        expect(result).to include('src="./images/arch.png"')
      end

      it "handles absolute paths" do
        content = '![Logo](/assets/logo.png){caption="Company logo"}'
        result = processor.preprocess(content)

        expect(result).to include('src="/assets/logo.png"')
      end

      it "handles URLs" do
        content = '![Remote](https://example.com/img.jpg){caption="Remote image"}'
        result = processor.preprocess(content)

        expect(result).to include('src="https://example.com/img.jpg"')
      end
    end

    context "with empty alt text" do
      it "handles empty alt attribute" do
        content = '![](image.png){caption="Decorative image"}'
        result = processor.preprocess(content)

        expect(result).to include('alt=""')
      end
    end

    context "with special characters" do
      it "escapes HTML in alt text" do
        content = '![Alt <script>](image.png){caption="Caption"}'
        result = processor.preprocess(content)

        expect(result).to include("alt=\"Alt &lt;script&gt;\"")
      end

      it "escapes HTML in caption" do
        content = '![Alt](image.png){caption="Caption <b>bold</b>"}'
        result = processor.preprocess(content)

        expect(result).to include("&lt;b&gt;bold&lt;/b&gt;")
      end

      it "escapes quotes in src" do
        content = '![Alt](image"test.png){caption="Caption"}'
        result = processor.preprocess(content)

        expect(result).to include('src="image&quot;test.png"')
      end
    end

    context "with regular images (no caption)" do
      it "leaves uncaptioned images unchanged" do
        content = "![Alt text](image.png)"
        result = processor.preprocess(content)

        expect(result).to eq("![Alt text](image.png)")
      end
    end

    context "with multiple images" do
      it "processes all captioned images", :aggregate_failures do
        content = <<~MD
          ![First](one.png){caption="Figure 1"}

          Some text here.

          ![Second](two.png){caption="Figure 2"}
        MD

        result = processor.preprocess(content)

        expect(result.scan("<figure").count).to eq(2)
        expect(result).to include("Figure 1")
        expect(result).to include("Figure 2")
      end

      it "processes mixed captioned and uncaptioned images", :aggregate_failures do
        content = <<~MD
          ![Captioned](one.png){caption="Has caption"}
          ![Uncaptioned](two.png)
        MD

        result = processor.preprocess(content)

        expect(result.scan("<figure").count).to eq(1)
        expect(result).to include("![Uncaptioned](two.png)")
      end
    end

    context "with surrounding content" do
      it "preserves surrounding markdown", :aggregate_failures do
        content = <<~MD
          # Heading

          Some paragraph.

          ![Image](img.png){caption="Caption"}

          More content.
        MD

        result = processor.preprocess(content)

        expect(result).to include("# Heading")
        expect(result).to include("Some paragraph.")
        expect(result).to include("More content.")
        expect(result).to include("<figure")
      end
    end

    context "with code blocks" do
      it "does not process image caption syntax inside code blocks", :aggregate_failures do
        content = <<~MARKDOWN
          ![Real](real.png){caption="Real caption"}

          ```markdown
          ![Example](example.png){caption="Example syntax"}
          ```
        MARKDOWN
        result = processor.preprocess(content)

        expect(result).to include("<figure")
        expect(result).to include('![Example](example.png){caption="Example syntax"}')
      end
    end
  end
end
