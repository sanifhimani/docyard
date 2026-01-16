# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::AbbreviationProcessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with single abbreviation" do
      it "wraps term in abbr tag", :aggregate_failures do
        content = "The API is great.\n\n*[API]: Application Programming Interface"
        result = processor.preprocess(content)

        expect(result).to include('<abbr class="docyard-abbr"')
        expect(result).to include(">API</abbr>")
      end

      it "includes definition in data attribute" do
        content = "The API is great.\n\n*[API]: Application Programming Interface"
        result = processor.preprocess(content)

        expect(result).to include('data-definition="Application Programming Interface"')
      end

      it "removes definition from content" do
        content = "The API is great.\n\n*[API]: Application Programming Interface"
        result = processor.preprocess(content)

        expect(result).not_to include("*[API]:")
      end
    end

    context "with multiple abbreviations" do
      it "processes all definitions", :aggregate_failures do
        content = "Use the API with JWT tokens.\n\n*[API]: Application Programming Interface\n*[JWT]: JSON Web Token"
        result = processor.preprocess(content)

        expect(result).to include(">API</abbr>")
        expect(result).to include(">JWT</abbr>")
        expect(result).to include('data-definition="Application Programming Interface"')
        expect(result).to include('data-definition="JSON Web Token"')
      end
    end

    context "with multiple occurrences" do
      it "wraps all occurrences of the term", :aggregate_failures do
        content = "The API is RESTful. This API supports JSON.\n\n*[API]: Application Programming Interface"
        result = processor.preprocess(content)

        expect(result.scan(">API</abbr>").count).to eq(2)
      end
    end

    context "with no abbreviations" do
      it "returns content unchanged" do
        content = "Just regular text without any definitions."
        result = processor.preprocess(content)

        expect(result).to eq(content)
      end
    end

    context "with term as part of larger word" do
      it "does not match partial words", :aggregate_failures do
        content = "The APIS and OAPIFY tools.\n\n*[API]: Application Programming Interface"
        result = processor.preprocess(content)

        expect(result).to include("APIS")
        expect(result).to include("OAPIFY")
        expect(result).not_to include(">APIS</abbr>")
        expect(result).not_to include(">OAPIFY</abbr>")
      end
    end

    context "with special characters in definition" do
      it "escapes HTML in definition", :aggregate_failures do
        content = "Use API here.\n\n*[API]: Handles <script> & \"quotes\""
        result = processor.preprocess(content)

        expect(result).to include("&lt;script&gt;")
        expect(result).to include("&amp;")
        expect(result).to include("&quot;quotes&quot;")
      end
    end

    context "with definition placement" do
      it "works with definitions at end of document", :aggregate_failures do
        content = "First paragraph about API.\n\nSecond paragraph.\n\n*[API]: Definition"
        result = processor.preprocess(content)

        expect(result).to include(">API</abbr>")
        expect(result).not_to include("*[API]:")
      end

      it "works with definitions anywhere in document" do
        content = "*[API]: Definition\n\nParagraph about API."
        result = processor.preprocess(content)

        expect(result).to include(">API</abbr>")
      end
    end

    context "with surrounding content" do
      it "preserves markdown structure", :aggregate_failures do
        content = "# Heading\n\nText with API here.\n\n## Another\n\n*[API]: Definition"
        result = processor.preprocess(content)

        expect(result).to include("# Heading")
        expect(result).to include("## Another")
        expect(result).to include(">API</abbr>")
      end
    end

    context "with case sensitivity" do
      it "matches case-sensitively", :aggregate_failures do
        content = "The API and the api are different.\n\n*[API]: Uppercase only"
        result = processor.preprocess(content)

        expect(result).to include(">API</abbr>")
        expect(result).not_to include(">api</abbr>")
        expect(result).to include(" the api are")
      end
    end

    context "with long definitions" do
      it "handles multi-word definitions" do
        content = "See the FAQ.\n\n*[FAQ]: Frequently Asked Questions about common issues and problems"
        result = processor.preprocess(content)

        expect(result).to include('data-definition="Frequently Asked Questions about common issues and problems"')
      end
    end

    context "with code blocks" do
      it "does not process definitions inside code blocks", :aggregate_failures do
        content = <<~MARKDOWN
          Use the API here.

          ```markdown
          *[API]: Application Programming Interface
          ```

          *[API]: Application Programming Interface
        MARKDOWN
        result = processor.preprocess(content)

        expect(result).to include(">API</abbr>")
        expect(result).to include("```markdown\n*[API]: Application Programming Interface\n```")
      end

      it "does not replace terms inside code blocks", :aggregate_failures do
        content = <<~MARKDOWN
          The API is great.

          ```ruby
          API_KEY = "secret"
          ```

          *[API]: Application Programming Interface
        MARKDOWN
        result = processor.preprocess(content)

        expect(result).to include(">API</abbr> is great")
        expect(result).to include('API_KEY = "secret"')
        expect(result).not_to include(">API</abbr>_KEY")
      end

      it "processes definitions outside code blocks only", :aggregate_failures do
        content = <<~MARKDOWN
          ```markdown
          *[FAKE]: Not a real definition
          ```

          Use the API.

          *[API]: Real definition
        MARKDOWN
        result = processor.preprocess(content)

        expect(result).to include(">API</abbr>")
        expect(result).not_to include(">FAKE</abbr>")
        expect(result).to include("*[FAKE]: Not a real definition")
      end
    end
  end
end
