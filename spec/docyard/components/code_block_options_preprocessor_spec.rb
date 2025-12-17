# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeBlockOptionsPreprocessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    it "extracts :line-numbers option from code fence" do
      content = "```ruby:line-numbers\nputs \"hello\"\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "ruby", title: nil, option: ":line-numbers", highlights: [] }])
    end

    it "extracts :no-line-numbers option from code fence" do
      content = "```js:no-line-numbers\nconsole.log(\"hello\")\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "js", title: nil, option: ":no-line-numbers", highlights: [] }])
    end

    it "extracts :line-numbers=N option from code fence" do
      content = "```python:line-numbers=10\nprint(\"hello\")\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "python", title: nil, option: ":line-numbers=10", highlights: [] }])
    end

    it "handles code fences without options" do
      content = "```ruby\nputs \"hello\"\n```"

      processor.preprocess(content)

      expect(context[:code_block_options]).to eq([{ lang: "ruby", title: nil, option: nil, highlights: [] }])
    end

    context "with line highlighting syntax" do
      it "extracts single line highlight" do
        content = "```ruby {3}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", title: nil, option: nil, highlights: [3] }])
      end

      it "extracts multiple individual lines" do
        content = "```ruby {1, 3, 5}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", title: nil, option: nil, highlights: [1, 3, 5] }])
      end

      it "extracts line ranges" do
        content = "```ruby {2-5}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", title: nil, option: nil, highlights: [2, 3, 4, 5] }])
      end

      it "extracts mixed individual lines and ranges" do
        content = "```ruby {1, 3-5, 8}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", title: nil, option: nil, highlights: [1, 3, 4, 5, 8] }])
      end

      it "combines highlight syntax with options" do
        content = "```ruby:line-numbers {2, 4}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", title: nil, option: ":line-numbers", highlights: [2, 4] }])
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

        expect(context[:code_block_options]).to eq([{ lang: "ruby", title: nil, option: nil, highlights: [1, 2, 3, 4] }])
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
          { lang: "ruby", title: nil, option: ":line-numbers", highlights: [] },
          { lang: "js", title: nil, option: ":no-line-numbers", highlights: [] },
          { lang: "python", title: nil, option: nil, highlights: [] }
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

    context "with custom title syntax" do
      it "extracts title from brackets" do
        content = "```js [config.js]\nconst x = 1;\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "js", title: "config.js", option: nil, highlights: [] }])
      end

      it "extracts title with spaces" do
        content = "```bash [My Script]\necho hello\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "bash", title: "My Script", option: nil, highlights: [] }])
      end

      it "combines title with options" do
        content = "```ruby [app.rb]:line-numbers\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", title: "app.rb", option: ":line-numbers", highlights: [] }])
      end

      it "combines title with highlights" do
        content = "```js [index.js] {1, 3}\nconst x = 1;\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "js", title: "index.js", option: nil, highlights: [1, 3] }])
      end

      it "combines title with options and highlights" do
        content = "```ruby [config.rb]:line-numbers {2-4}\nputs \"hello\"\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ruby", title: "config.rb", option: ":line-numbers", highlights: [2, 3, 4] }])
      end

      it "strips title from output", :aggregate_failures do
        content = "```js [filename.js]\nconst x = 1;\n```"

        result = processor.preprocess(content)

        expect(result).to include("```js")
        expect(result).not_to include("[filename.js]")
      end

      it "handles title with special characters" do
        content = "```ts [src/utils/helper.ts]\nconst x = 1;\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "ts", title: "src/utils/helper.ts", option: nil, highlights: [] }])
      end

      it "handles title with manual icon prefix" do
        content = "```bash [:rocket:Deploy Script]\necho deploy\n```"

        processor.preprocess(content)

        expect(context[:code_block_options]).to eq([{ lang: "bash", title: ":rocket:Deploy Script", option: nil, highlights: [] }])
      end
    end
  end

  describe "priority" do
    it "has priority 5 to run early in preprocessing" do
      expect(described_class.priority).to eq(5)
    end
  end
end
