# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeBlockFocusPreprocessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with JavaScript-style comments" do
      it "detects // [!code focus] markers" do
        content = "```javascript\nconst x = 1; // [!code focus]\n```"

        processor.preprocess(content)

        expect(context[:code_block_focus_lines]).to eq([{ 1 => true }])
      end
    end

    context "with Ruby/Python-style comments" do
      it "detects # [!code focus] markers" do
        content = "```ruby\nputs 'hello' # [!code focus]\n```"

        processor.preprocess(content)

        expect(context[:code_block_focus_lines]).to eq([{ 1 => true }])
      end
    end

    context "with CSS-style comments" do
      it "detects /* [!code focus] */ markers" do
        content = "```css\ncolor: red; /* [!code focus] */\n```"

        processor.preprocess(content)

        expect(context[:code_block_focus_lines]).to eq([{ 1 => true }])
      end
    end

    context "with SQL-style comments" do
      it "detects -- [!code focus] markers" do
        content = "```sql\nSELECT * FROM users -- [!code focus]\n```"

        processor.preprocess(content)

        expect(context[:code_block_focus_lines]).to eq([{ 1 => true }])
      end
    end

    context "with HTML-style comments" do
      it "detects <!-- [!code focus] --> markers" do
        content = "```html\n<div>hello</div> <!-- [!code focus] -->\n```"

        processor.preprocess(content)

        expect(context[:code_block_focus_lines]).to eq([{ 1 => true }])
      end
    end

    context "with Lisp-style comments" do
      it "detects ; [!code focus] markers" do
        content = "```lisp\n(print \"hello\") ; [!code focus]\n```"

        processor.preprocess(content)

        expect(context[:code_block_focus_lines]).to eq([{ 1 => true }])
      end
    end

    it "strips markers from output", :aggregate_failures do
      content = "```javascript\nconst x = 1; // [!code focus]\n```"

      result = processor.preprocess(content)

      expect(result).to include("const x = 1;")
      expect(result).not_to include("[!code focus]")
    end

    it "tracks multiple focus lines per block" do
      content = <<~MARKDOWN
        ```javascript
        const a = 1; // [!code focus]
        const b = 2;
        const c = 3; // [!code focus]
        const d = 4; // [!code focus]
        ```
      MARKDOWN

      processor.preprocess(content)

      expect(context[:code_block_focus_lines]).to eq([
                                                       { 1 => true, 3 => true, 4 => true }
                                                     ])
    end

    it "handles multiple code blocks independently" do
      content = <<~MARKDOWN
        ```javascript
        const x = 1; // [!code focus]
        ```

        ```ruby
        puts 'hello'
        puts 'world' # [!code focus]
        ```
      MARKDOWN

      processor.preprocess(content)

      expect(context[:code_block_focus_lines]).to eq([
                                                       { 1 => true },
                                                       { 2 => true }
                                                     ])
    end

    it "handles code blocks without focus markers" do
      content = "```ruby\nputs 'hello'\n```"

      processor.preprocess(content)

      expect(context[:code_block_focus_lines]).to eq([{}])
    end

    it "preserves content outside of code fences", :aggregate_failures do
      content = "# Header\n\nSome text.\n\n```javascript\nx = 1; // [!code focus]\n```\n\nMore text."

      result = processor.preprocess(content)

      expect(result).to include("# Header")
      expect(result).to include("Some text.")
      expect(result).to include("More text.")
    end

    it "handles whitespace variations in markers" do
      content = "```javascript\nconst x = 1; //  [!code  focus]\n```"

      processor.preprocess(content)

      expect(context[:code_block_focus_lines]).to eq([{ 1 => true }])
    end

    it "strips focus marker when diff marker appears first on same line", :aggregate_failures do
      content = "```javascript\nconst x = 1; // [!code ++] // [!code focus]\n```"

      result = processor.preprocess(content)

      expect(context[:code_block_focus_lines]).to eq([{ 1 => true }])
      expect(result).to include("// [!code ++]")
      expect(result).not_to include("[!code focus]")
    end
  end

  describe "priority" do
    it "has priority 7 to run after CodeBlockDiffPreprocessor" do
      expect(described_class.priority).to eq(7)
    end
  end
end
