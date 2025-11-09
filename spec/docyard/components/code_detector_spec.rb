# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Components::CodeDetector do
  describe ".detect" do
    context "with code-only content" do
      it "detects JavaScript code block" do
        content = "```javascript\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "js", source: "file-extension" })
      end

      it "detects TypeScript code block" do
        content = "```typescript\nlet x: string = 'hello';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "ts", source: "file-extension" })
      end

      it "detects Python code block" do
        content = "```python\nprint('hello')\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "py", source: "file-extension" })
      end

      it "detects Ruby code block" do
        content = "```ruby\nputs 'hello'\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "rb", source: "file-extension" })
      end

      it "detects Go code block" do
        content = "```go\nfmt.Println(\"hello\")\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "go", source: "file-extension" })
      end

      it "detects Rust code block" do
        content = "```rust\nprintln!(\"hello\");\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "rs", source: "file-extension" })
      end

      it "detects bash terminal commands" do
        content = "```bash\nnpm install\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "terminal-window", source: "phosphor" })
      end

      it "detects sh terminal commands" do
        content = "```sh\nls -la\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "terminal-window", source: "phosphor" })
      end

      it "detects shell terminal commands" do
        content = "```shell\necho 'hello'\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "terminal-window", source: "phosphor" })
      end

      it "detects powershell terminal commands" do
        content = "```powershell\nWrite-Host 'hello'\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "terminal-window", source: "phosphor" })
      end

      it "is case insensitive for language detection" do
        content = "```JavaScript\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "js", source: "file-extension" })
      end

      it "handles language aliases (js -> javascript)" do
        content = "```js\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "js", source: "file-extension" })
      end

      it "handles language aliases (ts -> typescript)" do
        content = "```ts\nlet x: string = 'hello';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "ts", source: "file-extension" })
      end

      it "handles language aliases (py -> python)" do
        content = "```py\nprint('hello')\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "py", source: "file-extension" })
      end

      it "handles language aliases (yml -> yaml)" do
        content = "```yml\nkey: value\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "yaml", source: "file-extension" })
      end

      it "uses fallback file icon for unknown language" do
        content = "```unknown\nsome code\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "file", source: "phosphor" })
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

    context "with all supported languages" do
      {
        "html" => "html",
        "css" => "css",
        "json" => "json",
        "yaml" => "yaml",
        "toml" => "toml",
        "sql" => "sql",
        "mysql" => "mysql",
        "postgresql" => "pgsql",
        "graphql" => "graphql",
        "vue" => "vue",
        "svelte" => "svelte",
        "proto" => "proto",
        "jsx" => "jsx",
        "tsx" => "tsx",
        "php" => "php"
      }.each do |lang, expected_extension|
        it "detects #{lang} code block" do
          content = "```#{lang}\nsome code\n```"
          result = described_class.detect(content)

          expect(result).to eq({ icon: expected_extension, source: "file-extension" })
        end
      end
    end

    context "with whitespace variations" do
      it "handles content with leading whitespace" do
        content = "  ```javascript\nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "js", source: "file-extension" })
      end

      it "handles content with trailing whitespace" do
        content = "```javascript\nconst foo = 'bar';\n```  "
        result = described_class.detect(content)

        expect(result).to eq({ icon: "js", source: "file-extension" })
      end

      it "handles content with whitespace around language identifier" do
        content = "```  javascript  \nconst foo = 'bar';\n```"
        result = described_class.detect(content)

        expect(result).to eq({ icon: "js", source: "file-extension" })
      end
    end
  end
end
