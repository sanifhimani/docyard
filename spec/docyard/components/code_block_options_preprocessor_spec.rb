# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeBlockOptionsPreprocessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    it "extracts :line-numbers option from code fence" do
      content = "```ruby:line-numbers\nputs \"hello\"\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "ruby", option: ":line-numbers", highlights: [] }])
    end

    it "extracts :no-line-numbers option from code fence" do
      content = "```js:no-line-numbers\nconsole.log(\"hello\")\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "js", option: ":no-line-numbers", highlights: [] }])
    end

    it "extracts :line-numbers=N option from code fence" do
      content = "```python:line-numbers=10\nprint(\"hello\")\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "python", option: ":line-numbers=10", highlights: [] }])
    end

    it "handles code fences without options" do
      content = "```ruby\nputs \"hello\"\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "ruby", option: nil, highlights: [] }])
    end

    context "with line highlighting syntax" do
      it "extracts single line highlight" do
        content = "```ruby {3}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", option: nil, highlights: [3] }])
      end

      it "extracts multiple individual lines" do
        content = "```ruby {1, 3, 5}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", option: nil, highlights: [1, 3, 5] }])
      end

      it "extracts line ranges" do
        content = "```ruby {2-5}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", option: nil, highlights: [2, 3, 4, 5] }])
      end

      it "extracts mixed individual lines and ranges" do
        content = "```ruby {1, 3-5, 8}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", option: nil, highlights: [1, 3, 4, 5, 8] }])
      end

      it "combines highlight syntax with options" do
        content = "```ruby:line-numbers {2, 4}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", option: ":line-numbers", highlights: [2, 4] }])
      end

      it "strips highlight syntax from output", :aggregate_failures do
        content = "```ruby {1, 3-5}\nputs \"hello\"\n```"

        result = processor.preprocess(content)

        expect(result).to include("```ruby")
        expect(result).not_to include("{1, 3-5}")
      end

      it "deduplicates overlapping ranges" do
        content = "```ruby {1-3, 2-4}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", option: nil, highlights: [1, 2, 3, 4] }])
      end
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
          { lang: "ruby", option: ":line-numbers", highlights: [] },
          { lang: "js", option: ":no-line-numbers", highlights: [] },
          { lang: "python", option: nil, highlights: [] }
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
