# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Components::Support::CodeDetector do
  describe ".detect" do
    context "with code-only content" do
      it "detects JavaScript code block" do
        content = "```javascript\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "javascript" })
      end

      it "detects TypeScript code block" do
        content = "```typescript\nlet x: string = 'hello';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "typescript" })
      end

      it "detects Python code block" do
        content = "```python\nprint('hello')\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "python" })
      end

      it "detects Ruby code block" do
        content = "```ruby\nputs 'hello'\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "ruby" })
      end

      it "detects Go code block" do
        content = "```go\nfmt.Println(\"hello\")\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "go" })
      end

      it "detects Rust code block" do
        content = "```rust\nprintln!(\"hello\");\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "rust" })
      end

      it "detects bash commands" do
        content = "```bash\nnpm install\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "bash" })
      end

      it "detects sh commands" do
        content = "```sh\nls -la\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "sh" })
      end

      it "detects shell commands" do
        content = "```shell\necho 'hello'\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "shell" })
      end

      it "detects powershell commands" do
        content = "```powershell\nWrite-Host 'hello'\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "powershell" })
      end

      it "is case insensitive for language detection" do
        content = "```JavaScript\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "javascript" })
      end

      it "returns language alias as-is (js)" do
        content = "```js\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "js" })
      end

      it "returns language alias as-is (ts)" do
        content = "```ts\nlet x: string = 'hello';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "ts" })
      end

      it "returns language alias as-is (py)" do
        content = "```py\nprint('hello')\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "py" })
      end

      it "returns language alias as-is (yml)" do
        content = "```yml\nkey: value\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "yml" })
      end

      it "returns unknown language as-is" do
        content = "```unknown\nsome code\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "unknown" })
      end
    end

    context "with mixed content" do
      it "returns nil when code block has text before it" do
        content = "Some text\n```javascript\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to be_nil
      end

      it "returns nil when code block has text after it" do
        content = "```javascript\nconst foo = 'bar';\n```\nSome text"
        result = described_class.detect(content)

        expect(result).to be_nil
      end

      it "returns nil when there are multiple code blocks" do
        content = "```javascript\nconst foo = 'bar';\n```\n```python\nprint('hello')\n```"
        result = described_class.detect(content)

        expect(result).to be_nil
      end

      it "returns nil for mixed code and text content" do
        content = "Here's some code:\n```javascript\nconst foo = 'bar';\n```\nAnd here's more text."
        result = described_class.detect(content)

        expect(result).to be_nil
      end
    end

    context "with plain text content" do
      it "returns nil for plain text without code blocks" do
        content = "Just some plain text"
        result = described_class.detect(content)

        expect(result).to be_nil
      end

      it "returns nil for empty content" do
        content = ""
        result = described_class.detect(content)

        expect(result).to be_nil
      end

      it "returns nil for whitespace only" do
        content = "   \n  \n  "
        result = described_class.detect(content)

        expect(result).to be_nil
      end
    end

    context "with invalid code block syntax" do
      it "returns nil when language has spaces" do
        content = "```java script\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to be_nil
      end

      it "returns nil when code block is not properly closed" do
        content = "```javascript\nconst foo = 'bar';"
        result = described_class.detect(content)

        expect(result).to be_nil
      end

      it "returns nil when code block is not properly opened" do
        content = "const foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to be_nil
      end

      it "returns nil when language identifier is missing" do
        content = "```\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to be_nil
      end
    end

    context "with various languages" do
      %w[html css json yaml toml sql mysql postgresql graphql vue svelte proto jsx tsx php].each do |lang|
        it "detects #{lang} code block" do
          content = "```#{lang}\nsome code\n```"
          result = described_class.detect(content)

          expect(result).to eq({ language: lang })
        end
      end
    end

    context "with whitespace variations" do
      it "handles content with leading whitespace" do
        content = "  ```javascript\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "javascript" })
      end

      it "handles content with trailing whitespace" do
        content = "```javascript\nconst foo = 'bar';\n```  "
        result = described_class.detect(content)

        expect(result).to eq({ language: "javascript" })
      end

      it "handles content with whitespace around language identifier" do
        content = "```  javascript  \nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ language: "javascript" })
      end
    end
  end
end
