# frozen_string_literal: true

RSpec.describe Docyard::Components::CalloutProcessor do
  let(:processor) { described_class.new }

  describe "#preprocess" do
    context "with ::: syntax callouts" do
      it "converts note callout with default title", :aggregate_failures do
        markdown = <<~MD
          :::note
          This is a note
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-callout docyard-callout--note"')
        expect(result).to include('class="docyard-callout__title">Note</div>')
        expect(result).to include("This is a note")
        expect(result).to include('role="note"')
      end

      it "converts tip callout with custom title", :aggregate_failures do
        markdown = <<~MD
          :::tip Pro Tip
          This is helpful advice
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-callout docyard-callout--tip"')
        expect(result).to include('class="docyard-callout__title">Pro Tip</div>')
        expect(result).to include("This is helpful advice")
      end

      it "converts important callout", :aggregate_failures do
        markdown = <<~MD
          :::important
          Critical information
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-callout docyard-callout--important"')
        expect(result).to include('class="docyard-callout__title">Important</div>')
      end

      it "converts warning callout", :aggregate_failures do
        markdown = <<~MD
          :::warning
          Be careful here
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-callout docyard-callout--warning"')
        expect(result).to include('role="alert"')
      end

      it "converts danger callout", :aggregate_failures do
        markdown = <<~MD
          :::danger
          This is dangerous
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-callout docyard-callout--danger"')
        expect(result).to include('role="alert"')
      end

      it "includes default icon for each type", :aggregate_failures do
        markdown = ":::note\nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("ph-")
        expect(result).to include('class="docyard-callout__icon"')
      end

      it "processes markdown content inside callouts", :aggregate_failures do
        markdown = <<~MD
          :::tip
          This has **bold** and `code` text.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("<strong>bold</strong>")
        expect(result).to include("<code>code</code>")
      end

      it "processes code blocks inside callouts", :aggregate_failures do
        markdown = ":::note\nExample code:\n\n```ruby\nputs \"hello\"\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("Example code:")
        expect(result).to include("highlight")
        expect(result).to include("puts")
        expect(result).to include("hello")
        expect(result).to include("language-ruby")
      end

      it "handles multi-line content", :aggregate_failures do
        markdown = <<~MD
          :::tip
          First paragraph.

          Second paragraph.
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("First paragraph")
        expect(result).to include("Second paragraph")
      end

      it "ignores unknown callout types", :aggregate_failures do
        markdown = <<~MD
          :::unknown
          This should not be converted
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to eq(markdown)
        expect(result).not_to include("docyard-callout")
      end

      it "handles case-insensitive type names", :aggregate_failures do
        markdown = <<~MD
          :::NOTE
          Uppercase note
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-callout docyard-callout--note"')
      end

      it "handles multiple callouts in same document", :aggregate_failures do
        markdown = ":::note\nFirst callout\n:::\n\nSome text\n\n:::tip\nSecond callout\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("docyard-callout--note")
        expect(result).to include("docyard-callout--tip")
        expect(result).to include("First callout")
        expect(result).to include("Second callout")
      end
    end

    context "with edge cases" do
      it "handles empty callout content" do
        markdown = ":::note\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("docyard-callout")
      end

      it "handles callouts with only whitespace in title" do
        markdown = ":::note   \nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('docyard-callout__title">Note</div>')
      end

      it "does not match incomplete syntax" do
        markdown = ":::note\nNo closing tag"
        result = processor.preprocess(markdown)

        expect(result).to eq(markdown)
      end

      it "preserves content outside callouts", :aggregate_failures do
        markdown = <<~MD
          Regular paragraph

          :::note
          Callout content
          :::

          Another paragraph
        MD

        result = processor.preprocess(markdown)

        expect(result).to include("Regular paragraph")
        expect(result).to include("Another paragraph")
      end
    end
  end

  describe "#postprocess" do
    context "with GitHub-style alerts" do
      it "converts [!NOTE] alert", :aggregate_failures do
        html = "<blockquote><p>[!NOTE]<br />This is a note</p></blockquote>"
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-callout docyard-callout--note"')
        expect(result).to include('class="docyard-callout__title">Note</div>')
        expect(result).to include("This is a note")
      end

      it "converts [!TIP] alert", :aggregate_failures do
        html = "<blockquote><p>[!TIP]<br />Helpful tip</p></blockquote>"
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-callout docyard-callout--tip"')
      end

      it "converts [!IMPORTANT] alert", :aggregate_failures do
        html = "<blockquote><p>[!IMPORTANT]<br />Critical info</p></blockquote>"
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-callout docyard-callout--important"')
      end

      it "converts [!WARNING] alert", :aggregate_failures do
        html = "<blockquote><p>[!WARNING]<br />Be careful</p></blockquote>"
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-callout docyard-callout--warning"')
        expect(result).to include('role="alert"')
      end

      it "converts [!CAUTION] alert to danger type", :aggregate_failures do
        html = "<blockquote><p>[!CAUTION]<br />Dangerous</p></blockquote>"
        result = processor.postprocess(html)

        expect(result).to include('class="docyard-callout docyard-callout--danger"')
        expect(result).to include('role="alert"')
      end

      it "handles alert without <br />", :aggregate_failures do
        html = "<blockquote><p>[!NOTE] This is a note</p></blockquote>"
        result = processor.postprocess(html)

        expect(result).to include("docyard-callout--note")
        expect(result).to include("This is a note")
      end

      it "handles multi-paragraph GitHub alerts", :aggregate_failures do
        html = "<blockquote><p>[!NOTE]<br />First paragraph</p><p>Second paragraph</p></blockquote>"
        result = processor.postprocess(html)

        expect(result).to include("First paragraph")
        expect(result).to include("Second paragraph")
      end

      it "includes icon for GitHub alerts", :aggregate_failures do
        html = "<blockquote><p>[!NOTE]<br />Content</p></blockquote>"
        result = processor.postprocess(html)

        expect(result).to include("ph-")
        expect(result).to include('class="docyard-callout__icon"')
      end

      it "preserves HTML content in alerts", :aggregate_failures do
        html = "<blockquote><p>[!TIP]<br />Use <code>this command</code> carefully</p></blockquote>"
        result = processor.postprocess(html)

        expect(result).to include("<code>this command</code>")
      end

      it "does not convert regular blockquotes", :aggregate_failures do
        html = "<blockquote><p>Regular quote</p></blockquote>"
        result = processor.postprocess(html)

        expect(result).to eq(html)
        expect(result).not_to include("docyard-callout")
      end
    end
  end

  describe "icon mapping" do
    it "uses info icon for note type" do
      markdown = ":::note\nContent\n:::"
      result = processor.preprocess(markdown)

      expect(result).to include("ph-")
    end

    it "uses lightbulb icon for tip type" do
      markdown = ":::tip\nContent\n:::"
      result = processor.preprocess(markdown)

      expect(result).to include("ph-")
    end

    it "uses warning-circle icon for important type" do
      markdown = ":::important\nContent\n:::"
      result = processor.preprocess(markdown)

      expect(result).to include("ph-")
    end

    it "uses warning icon for warning type" do
      markdown = ":::warning\nContent\n:::"
      result = processor.preprocess(markdown)

      expect(result).to include("ph-")
    end

    it "uses siren icon for danger type" do
      markdown = ":::danger\nContent\n:::"
      result = processor.preprocess(markdown)

      expect(result).to include("ph-")
    end
  end

  describe "ARIA roles" do
    it "uses role=note for note type" do
      markdown = ":::note\nContent\n:::"
      result = processor.preprocess(markdown)

      expect(result).to include('role="note"')
    end

    it "uses role=alert for warning type" do
      markdown = ":::warning\nContent\n:::"
      result = processor.preprocess(markdown)

      expect(result).to include('role="alert"')
    end

    it "uses role=alert for danger type" do
      markdown = ":::danger\nContent\n:::"
      result = processor.preprocess(markdown)

      expect(result).to include('role="alert"')
    end
  end

  describe "code block preservation" do
    it "does not process callout syntax inside code blocks", :aggregate_failures do
      markdown = <<~MD
        :::note
        Real callout
        :::

        ```markdown
        :::note
        Example callout syntax
        :::
        ```
      MD

      result = processor.preprocess(markdown)

      expect(result).to include('class="docyard-callout docyard-callout--note"')
      expect(result.scan('class="docyard-callout docyard-callout--').count).to eq(1)
      expect(result).to include(":::note\nExample callout syntax\n:::")
    end
  end
end
