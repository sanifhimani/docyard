# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeBlockOptionsPreprocessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    it "extracts :line-numbers option from code fence" do
      content = "```ruby:line-numbers\nputs \"hello\"\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "ruby", option: ":line-numbers" }])
    end

    it "extracts :no-line-numbers option from code fence" do
      content = "```js:no-line-numbers\nconsole.log(\"hello\")\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "js", option: ":no-line-numbers" }])
    end

    it "extracts :line-numbers=N option from code fence" do
      content = "```python:line-numbers=10\nprint(\"hello\")\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "python", option: ":line-numbers=10" }])
    end

    it "handles code fences without options" do
      content = "```ruby\nputs \"hello\"\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "ruby", option: nil }])
    end

    it "strips options from the code fence", :aggregate_failures do
      content = "```ruby:line-numbers\nputs \"hello\"\n```"

      result = processor.preprocess(content)

      expect(result).to include("```ruby")
      expect(result).not_to include(":line-numbers")
    end

    it "handles multiple code blocks" do
      content = [
        "```ruby:line-numbers", "puts \"first\"", "```", "",
        "```js:no-line-numbers", "console.log(\"second\")", "```", "",
        "```python", "print(\"third\")", "```"
      ].join("\n")

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq(
        [
          { lang: "ruby", option: ":line-numbers" },
          { lang: "js", option: ":no-line-numbers" },
          { lang: "python", option: nil }
        ]
      )
    end

    it "preserves content outside of code fences", :aggregate_failures do
      content = "# Header\n\nSome paragraph text.\n\n```ruby:line-numbers\ncode\n```\n\nMore text."

      result = processor.preprocess(content)

      expect(result).to include("# Header")
      expect(result).to include("Some paragraph text.")
      expect(result).to include("More text.")
    end
  end

  describe "priority" do
    it "has priority 5 to run early in preprocessing" do
      expect(described_class.priority).to eq(5)
    end
  end
end
