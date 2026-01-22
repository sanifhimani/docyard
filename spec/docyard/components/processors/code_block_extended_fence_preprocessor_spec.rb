# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::CodeBlockExtendedFencePreprocessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with 4-backtick fence" do
      it "converts to 3-backtick fence", :aggregate_failures do
        content = "````js\nconst x = 1;\n````"

        result = processor.preprocess(content)

        expect(result).to include("```js")
        expect(result).to include("```")
      end

      it "escapes inner backticks with placeholders", :aggregate_failures do
        content = "````md\n```js\nconsole.log('hi');\n```\n````"

        result = processor.preprocess(content)

        expect(result).not_to include("```js")
        expect(result).to include("\u200B\u200B\u200B") # backtick placeholder
      end

      it "escapes code markers with placeholders", :aggregate_failures do
        content = "````js\nconst x = 1; // [!code ++]\n````"

        result = processor.preprocess(content)

        expect(result).to include("\u200B!\u200Bcode") # code marker placeholder
        expect(result).not_to include("[!code")
      end
    end

    context "with 5+ backtick fence" do
      it "converts 5-backtick fence" do
        content = "`````md\n````js\ncode\n````\n`````"

        result = processor.preprocess(content)

        expect(result).to start_with("```md")
      end

      it "converts 6-backtick fence" do
        content = "``````text\ncontent\n``````"

        result = processor.preprocess(content)

        expect(result).to start_with("```text")
      end
    end

    context "without language" do
      it "defaults to text language" do
        content = "````\nplain content\n````"

        result = processor.preprocess(content)

        expect(result).to start_with("```text")
      end
    end

    context "with regular 3-backtick fences" do
      it "does not modify regular code fences" do
        content = "```js\nconst x = 1;\n```"

        result = processor.preprocess(content)

        expect(result).to eq(content)
      end
    end

    context "with mixed content" do
      it "processes only extended fences", :aggregate_failures do
        content = "Regular text\n\n```ruby\nputs 'normal'\n```\n\n````md\n```js\ninner\n```\n````\n\nMore text"

        result = processor.preprocess(content)

        expect(result).to include("Regular text")
        expect(result).to include("```ruby")
        expect(result).to include("puts 'normal'")
        expect(result).to include("More text")
      end
    end
  end
end
