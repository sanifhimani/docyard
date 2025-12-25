# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeBlockDiffPreprocessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with JavaScript-style comments" do
      it "detects // [!code ++] markers" do
        content = "```javascript\nconst x = 1; // [!code ++]\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :addition }])
      end

      it "detects // [!code --] markers" do
        content = "```javascript\nconst x = 1; // [!code --]\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :deletion }])
      end
    end

    context "with Ruby/Python-style comments" do
      it "detects # [!code ++] markers" do
        content = "```ruby\nputs 'hello' # [!code ++]\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :addition }])
      end

      it "detects # [!code --] markers" do
        content = "```python\nprint('hello') # [!code --]\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :deletion }])
      end
    end

    context "with CSS-style comments" do
      it "detects /* [!code ++] */ markers" do
        content = "```css\ncolor: red; /* [!code ++] */\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :addition }])
      end

      it "detects /* [!code --] */ markers" do
        content = "```css\ncolor: blue; /* [!code --] */\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :deletion }])
      end
    end

    context "with SQL-style comments" do
      it "detects -- [!code ++] markers" do
        content = "```sql\nSELECT * FROM users -- [!code ++]\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :addition }])
      end

      it "detects -- [!code --] markers" do
        content = "```sql\nDELETE FROM users -- [!code --]\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :deletion }])
      end
    end

    context "with HTML-style comments" do
      it "detects <!-- [!code ++] --> markers" do
        content = "```html\n<div>hello</div> <!-- [!code ++] -->\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :addition }])
      end

      it "detects <!-- [!code --] --> markers" do
        content = "```html\n<div>removed</div> <!-- [!code --] -->\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :deletion }])
      end
    end

    context "with Lisp-style comments" do
      it "detects ; [!code ++] markers" do
        content = "```lisp\n(print \"hello\") ; [!code ++]\n```"

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :addition }])
      end
    end

    it "strips markers from output", :aggregate_failures do
      content = "```javascript\nconst x = 1; // [!code ++]\n```"

      result = processor.preprocess(content)

      expect(result).to include("const x = 1;")
      expect(result).not_to include("[!code ++]")
    end

    it "tracks multiple diff lines per block" do
      content = <<~MARKDOWN
        ```javascript
        const a = 1; // [!code --]
        const b = 2; // [!code ++]
        const c = 3;
        const d = 4; // [!code ++]
        ```
      MARKDOWN

      processor.preprocess(content)

      expect(context[:code_block_diff_lines]).to eq([
                                                      { 1 => :deletion, 2 => :addition, 4 => :addition }
                                                    ])
    end

    it "handles multiple code blocks independently" do
      content = <<~MARKDOWN
        ```javascript
        const x = 1; // [!code ++]
        ```

        ```ruby
        puts 'hello' # [!code --]
        puts 'world' # [!code ++]
        ```
      MARKDOWN

      processor.preprocess(content)

      expect(context[:code_block_diff_lines]).to eq([
                                                      { 1 => :addition },
                                                      { 1 => :deletion, 2 => :addition }
                                                    ])
    end

    it "handles code blocks without diff markers" do
      content = "```ruby\nputs 'hello'\n```"

      processor.preprocess(content)

      expect(context[:code_block_diff_lines]).to eq([{}])
    end

    it "preserves content outside of code fences", :aggregate_failures do
      content = "# Header\n\nSome text.\n\n```javascript\nx = 1; // [!code ++]\n```\n\nMore text."

      result = processor.preprocess(content)

      expect(result).to include("# Header")
      expect(result).to include("Some text.")
      expect(result).to include("More text.")
    end

    it "handles whitespace variations in markers" do
      content = "```javascript\nconst x = 1; //  [!code  ++]\n```"

      processor.preprocess(content)

      expect(context[:code_block_diff_lines]).to eq([{ 1 => :addition }])
    end

    it "strips diff marker when followed by focus marker on same line", :aggregate_failures do
      content = "```javascript\nconst x = 1; // [!code ++] // [!code focus]\n```"

      result = processor.preprocess(content)

      expect(context[:code_block_diff_lines]).to eq([{ 1 => :addition }])
      expect(result).to include("// [!code focus]")
      expect(result).not_to include("[!code ++]")
    end

    context "with error markers" do
      it "detects // [!code error] markers" do
        content = "```javascript\nconsole.log('error'); // [!code error]\n```"

        processor.preprocess(content)

        expect(context[:code_block_error_lines]).to eq([{ 1 => true }])
      end

      it "detects # [!code error] markers" do
        content = "```ruby\nputs 'error' # [!code error]\n```"

        processor.preprocess(content)

        expect(context[:code_block_error_lines]).to eq([{ 1 => true }])
      end

      it "detects /* [!code error] */ markers" do
        content = "```css\ncolor: red; /* [!code error] */\n```"

        processor.preprocess(content)

        expect(context[:code_block_error_lines]).to eq([{ 1 => true }])
      end

      it "detects -- [!code error] markers" do
        content = "```sql\nSELECT * FROM users -- [!code error]\n```"

        processor.preprocess(content)

        expect(context[:code_block_error_lines]).to eq([{ 1 => true }])
      end

      it "detects <!-- [!code error] --> markers" do
        content = "```html\n<div>error</div> <!-- [!code error] -->\n```"

        processor.preprocess(content)

        expect(context[:code_block_error_lines]).to eq([{ 1 => true }])
      end

      it "detects ; [!code error] markers" do
        content = "```lisp\n(error \"msg\") ; [!code error]\n```"

        processor.preprocess(content)

        expect(context[:code_block_error_lines]).to eq([{ 1 => true }])
      end

      it "strips error markers from output", :aggregate_failures do
        content = "```javascript\nconsole.log('error'); // [!code error]\n```"

        result = processor.preprocess(content)

        expect(result).to include("console.log('error');")
        expect(result).not_to include("[!code error]")
      end
    end

    context "with warning markers" do
      it "detects // [!code warning] markers" do
        content = "```javascript\nconsole.warn('warning'); // [!code warning]\n```"

        processor.preprocess(content)

        expect(context[:code_block_warning_lines]).to eq([{ 1 => true }])
      end

      it "detects # [!code warning] markers" do
        content = "```ruby\nputs 'warning' # [!code warning]\n```"

        processor.preprocess(content)

        expect(context[:code_block_warning_lines]).to eq([{ 1 => true }])
      end

      it "detects /* [!code warning] */ markers" do
        content = "```css\ncolor: orange; /* [!code warning] */\n```"

        processor.preprocess(content)

        expect(context[:code_block_warning_lines]).to eq([{ 1 => true }])
      end

      it "detects -- [!code warning] markers" do
        content = "```sql\nUPDATE users SET admin = true -- [!code warning]\n```"

        processor.preprocess(content)

        expect(context[:code_block_warning_lines]).to eq([{ 1 => true }])
      end

      it "detects <!-- [!code warning] --> markers" do
        content = "```html\n<div>warning</div> <!-- [!code warning] -->\n```"

        processor.preprocess(content)

        expect(context[:code_block_warning_lines]).to eq([{ 1 => true }])
      end

      it "detects ; [!code warning] markers" do
        content = "```lisp\n(warn \"msg\") ; [!code warning]\n```"

        processor.preprocess(content)

        expect(context[:code_block_warning_lines]).to eq([{ 1 => true }])
      end

      it "strips warning markers from output", :aggregate_failures do
        content = "```javascript\nconsole.warn('warning'); // [!code warning]\n```"

        result = processor.preprocess(content)

        expect(result).to include("console.warn('warning');")
        expect(result).not_to include("[!code warning]")
      end
    end

    context "with combined markers" do
      it "handles diff, error, and warning on different lines", :aggregate_failures do
        content = <<~MARKDOWN
          ```javascript
          const a = 1; // [!code ++]
          const b = 2; // [!code error]
          const c = 3; // [!code warning]
          const d = 4;
          ```
        MARKDOWN

        processor.preprocess(content)

        expect(context[:code_block_diff_lines]).to eq([{ 1 => :addition }])
        expect(context[:code_block_error_lines]).to eq([{ 2 => true }])
        expect(context[:code_block_warning_lines]).to eq([{ 3 => true }])
      end

      it "handles multiple error lines" do
        content = <<~MARKDOWN
          ```javascript
          const a = 1; // [!code error]
          const b = 2;
          const c = 3; // [!code error]
          ```
        MARKDOWN

        processor.preprocess(content)

        expect(context[:code_block_error_lines]).to eq([{ 1 => true, 3 => true }])
      end

      it "handles multiple warning lines" do
        content = <<~MARKDOWN
          ```javascript
          const a = 1; // [!code warning]
          const b = 2;
          const c = 3; // [!code warning]
          ```
        MARKDOWN

        processor.preprocess(content)

        expect(context[:code_block_warning_lines]).to eq([{ 1 => true, 3 => true }])
      end
    end
  end

  describe "priority" do
    it "has priority 6 to run after CodeBlockOptionsPreprocessor" do
      expect(described_class.priority).to eq(6)
    end
  end
end
