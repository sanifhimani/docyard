# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Components::CodeBlockFeatureExtractor do
  describe ".process_markdown" do
    context "with basic code blocks" do
      it "returns cleaned markdown and empty blocks for code without features", :aggregate_failures do
        markdown = "```javascript\nconst x = 1;\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:cleaned_markdown]).to eq("```javascript\nconst x = 1;\n```")
        expect(result[:blocks].length).to eq(1)
        expect(result[:blocks][0][:lang]).to eq("javascript")
      end

      it "extracts language from code fence" do
        markdown = "```typescript\nconst x: number = 1;\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:lang]).to eq("typescript")
      end
    end

    context "with code block titles" do
      it "extracts title from code fence", :aggregate_failures do
        markdown = "```js [utils/helper.js]\nconst x = 1;\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:title]).to eq("utils/helper.js")
        expect(result[:cleaned_markdown]).to eq("```js\nconst x = 1;\n```")
      end
    end

    context "with line numbers option" do
      it "extracts line-numbers option", :aggregate_failures do
        markdown = "```js:line-numbers\nconst x = 1;\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:option]).to eq(":line-numbers")
        expect(result[:cleaned_markdown]).to eq("```js\nconst x = 1;\n```")
      end

      it "extracts line-numbers with start line", :aggregate_failures do
        markdown = "```js:line-numbers=10\nconst x = 1;\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:option]).to eq(":line-numbers=10")
      end
    end

    context "with line highlights" do
      it "extracts single line highlight", :aggregate_failures do
        markdown = "```js {2}\nconst x = 1;\nconst y = 2;\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:highlights]).to eq([2])
        expect(result[:cleaned_markdown]).to eq("```js\nconst x = 1;\nconst y = 2;\n```")
      end

      it "extracts multiple line highlights", :aggregate_failures do
        markdown = "```js {1,3}\nconst x = 1;\nconst y = 2;\nconst z = 3;\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:highlights]).to eq([1, 3])
      end

      it "extracts range highlights", :aggregate_failures do
        markdown = "```js {2-4}\nline1\nline2\nline3\nline4\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:highlights]).to eq([2, 3, 4])
      end

      it "extracts mixed single and range highlights", :aggregate_failures do
        markdown = "```js {1,3-5}\nline1\nline2\nline3\nline4\nline5\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:highlights]).to eq([1, 3, 4, 5])
      end
    end

    context "with focus markers" do
      it "extracts focus lines with // comment style", :aggregate_failures do
        markdown = "```js\nconst x = 1;\nconst y = 2;  // [!code focus]\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:focus_lines]).to eq({ 2 => true })
        expect(result[:cleaned_markdown]).to include("const y = 2;")
        expect(result[:cleaned_markdown]).not_to include("[!code focus]")
      end

      it "extracts focus lines with # comment style", :aggregate_failures do
        markdown = "```py\nx = 1\ny = 2  # [!code focus]\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:focus_lines]).to eq({ 2 => true })
      end

      it "extracts focus lines with /* */ comment style", :aggregate_failures do
        markdown = "```css\n.foo { color: red; }\n.bar { color: blue; }  /* [!code focus] */\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:focus_lines]).to eq({ 2 => true })
      end

      it "extracts focus lines with -- comment style", :aggregate_failures do
        markdown = "```sql\nSELECT * FROM users;\nWHERE active = true;  -- [!code focus]\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:focus_lines]).to eq({ 2 => true })
      end

      it "extracts focus lines with <!-- --> comment style", :aggregate_failures do
        markdown = "```html\n<div>Hello</div>\n<p>World</p>  <!-- [!code focus] -->\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:focus_lines]).to eq({ 2 => true })
      end

      it "extracts multiple focus lines", :aggregate_failures do
        markdown = "```js\nconst x = 1;  // [!code focus]\nconst y = 2;\nconst z = 3;  // [!code focus]\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:focus_lines]).to eq({ 1 => true, 3 => true })
      end
    end

    context "with diff markers" do
      it "extracts addition diff markers", :aggregate_failures do
        markdown = "```js\nconst x = 1;\nconst y = 2;  // [!code ++]\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:diff_lines]).to eq({ 2 => :addition })
        expect(result[:cleaned_markdown]).not_to include("[!code ++]")
      end

      it "extracts deletion diff markers", :aggregate_failures do
        markdown = "```js\nconst x = 1;\nconst y = 2;  // [!code --]\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:diff_lines]).to eq({ 2 => :deletion })
      end

      it "extracts diff markers with # comment style", :aggregate_failures do
        markdown = "```py\nx = 1\ny = 2  # [!code ++]\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:diff_lines]).to eq({ 2 => :addition })
      end

      it "extracts mixed addition and deletion", :aggregate_failures do
        markdown = "```js\nconst old = 1;  // [!code --]\nconst new = 2;  // [!code ++]\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:diff_lines]).to eq({ 1 => :deletion, 2 => :addition })
      end
    end

    context "with combined features" do
      it "extracts all features from a single code block", :aggregate_failures do
        markdown = <<~MD.chomp
          ```ts [config.ts]:line-numbers {1}
          const x = 1;
          const y = 2;  // [!code focus]
          const z = 3;  // [!code ++]
          ```
        MD
        result = described_class.process_markdown(markdown)

        block = result[:blocks][0]
        expect(block[:lang]).to eq("ts")
        expect(block[:title]).to eq("config.ts")
        expect(block[:option]).to eq(":line-numbers")
        expect(block[:highlights]).to eq([1])
        expect(block[:focus_lines]).to eq({ 2 => true })
        expect(block[:diff_lines]).to eq({ 3 => :addition })
      end

      it "handles diff and focus on the same line", :aggregate_failures do
        markdown = "```js\nconst x = 1;  // [!code ++]  // [!code focus]\n```"
        result = described_class.process_markdown(markdown)

        expect(result[:blocks][0][:diff_lines]).to eq({ 1 => :addition })
        expect(result[:blocks][0][:focus_lines]).to eq({ 1 => true })
      end
    end

    context "with multiple code blocks" do
      it "processes each code block independently", :aggregate_failures do
        markdown = <<~MD
          ```js
          const x = 1;  // [!code focus]
          ```

          Some text

          ```py
          y = 2  # [!code ++]
          ```
        MD

        result = described_class.process_markdown(markdown)

        expect(result[:blocks].length).to eq(2)
        expect(result[:blocks][0][:lang]).to eq("js")
        expect(result[:blocks][0][:focus_lines]).to eq({ 1 => true })
        expect(result[:blocks][1][:lang]).to eq("py")
        expect(result[:blocks][1][:diff_lines]).to eq({ 1 => :addition })
      end
    end
  end

  describe ".extract_diff_lines" do
    it "returns empty hash for content without diff markers", :aggregate_failures do
      result = described_class.extract_diff_lines("const x = 1;\n")

      expect(result[:lines]).to eq({})
      expect(result[:cleaned_content]).to eq("const x = 1;\n")
    end
  end

  describe ".extract_focus_lines" do
    it "returns empty hash for content without focus markers", :aggregate_failures do
      result = described_class.extract_focus_lines("const x = 1;\n")

      expect(result[:lines]).to eq({})
      expect(result[:cleaned_content]).to eq("const x = 1;\n")
    end
  end

  describe ".parse_highlights" do
    it "returns empty array for nil input" do
      expect(described_class.parse_highlights(nil)).to eq([])
    end

    it "returns empty array for empty string" do
      expect(described_class.parse_highlights("")).to eq([])
    end

    it "returns empty array for whitespace-only string" do
      expect(described_class.parse_highlights("   ")).to eq([])
    end

    it "parses single line number" do
      expect(described_class.parse_highlights("5")).to eq([5])
    end

    it "parses multiple line numbers" do
      expect(described_class.parse_highlights("1, 3, 5")).to eq([1, 3, 5])
    end

    it "parses line range" do
      expect(described_class.parse_highlights("2-4")).to eq([2, 3, 4])
    end

    it "removes duplicates and sorts" do
      expect(described_class.parse_highlights("5, 3, 5, 1")).to eq([1, 3, 5])
    end
  end
end
