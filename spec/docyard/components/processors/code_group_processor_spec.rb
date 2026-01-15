# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::CodeGroupProcessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with basic code group" do
      let(:content) do
        <<~MARKDOWN
          :::code-group
          ```js [npm]
          npm install docyard
          ```

          ```js [yarn]
          yarn add docyard
          ```
          :::
        MARKDOWN
      end

      it "converts code-group to tabbed interface", :aggregate_failures do
        result = processor.preprocess(content)

        expect(result).to include('class="docyard-code-group"')
        expect(result).to include('role="tablist"')
        expect(result).to include('role="tab"')
        expect(result).to include('role="tabpanel"')
      end

      it "extracts tab labels from code block syntax", :aggregate_failures do
        result = processor.preprocess(content)

        expect(result).to include('data-label="npm"')
        expect(result).to include('data-label="yarn"')
        expect(result).to include("npm</button>")
        expect(result).to include("yarn</button>")
      end

      it "renders code blocks with syntax highlighting" do
        result = processor.preprocess(content)

        expect(result).to include('class="docyard-code-block"')
      end
    end

    context "with multiple tabs" do
      let(:content) do
        <<~MARKDOWN
          :::code-group
          ```bash [npm]
          npm install
          ```

          ```bash [yarn]
          yarn add
          ```

          ```bash [pnpm]
          pnpm add
          ```
          :::
        MARKDOWN
      end

      it "creates correct number of tabs and panels", :aggregate_failures do
        result = processor.preprocess(content)

        expect(result.scan('role="tab"').count).to eq(3)
        expect(result.scan('role="tabpanel"').count).to eq(3)
      end
    end

    context "with different languages" do
      let(:content) do
        <<~MARKDOWN
          :::code-group
          ```ruby [Ruby]
          puts "Hello"
          ```

          ```python [Python]
          print("Hello")
          ```

          ```javascript [JavaScript]
          console.log("Hello");
          ```
          :::
        MARKDOWN
      end

      it "handles mixed language code blocks", :aggregate_failures do
        result = processor.preprocess(content)

        expect(result).to include('data-label="Ruby"')
        expect(result).to include('data-label="Python"')
        expect(result).to include('data-label="JavaScript"')
      end
    end

    context "with no code-group blocks" do
      it "returns content unchanged" do
        content = "Just regular markdown without code groups."
        result = processor.preprocess(content)

        expect(result).to eq(content)
      end
    end

    context "with empty code-group" do
      it "returns empty string for code-group with no blocks" do
        content = ":::code-group\n:::"
        result = processor.preprocess(content)

        expect(result.strip).to eq("")
      end
    end

    context "with accessibility attributes" do
      let(:content) do
        <<~MARKDOWN
          :::code-group
          ```js [First]
          code
          ```

          ```js [Second]
          code
          ```
          :::
        MARKDOWN
      end

      it "sets correct aria attributes for first tab", :aggregate_failures do
        result = processor.preprocess(content)

        expect(result).to include('aria-selected="true"')
        expect(result).to include('aria-selected="false"')
        expect(result).to include('aria-hidden="false"')
        expect(result).to include('aria-hidden="true"')
      end
    end

    context "with special characters in labels" do
      it "escapes HTML in labels", :aggregate_failures do
        content = ":::code-group\n```js [<script>]\ncode\n```\n:::"
        result = processor.preprocess(content)

        expect(result).to include("&lt;script&gt;")
        expect(result).not_to include("<script>")
      end
    end

    context "with multiple code groups" do
      let(:content) do
        <<~MARKDOWN
          :::code-group
          ```js [A]
          first
          ```
          :::

          :::code-group
          ```js [B]
          second
          ```
          :::
        MARKDOWN
      end

      it "generates unique IDs for each group", :aggregate_failures do
        result = processor.preprocess(content)
        ids = result.scan(/data-code-group="([^"]+)"/).flatten

        expect(ids.length).to eq(2)
        expect(ids.uniq.length).to eq(2)
      end
    end

    context "with nomarkdown wrapping" do
      it "wraps output in nomarkdown tags", :aggregate_failures do
        content = ":::code-group\n```js [Test]\ncode\n```\n:::"
        result = processor.preprocess(content)

        expect(result).to include("{::nomarkdown}")
        expect(result).to include("{:/nomarkdown}")
      end
    end

    context "with line highlighting" do
      let(:content) do
        <<~MARKDOWN
          :::code-group
          ```js [JavaScript] {2}
          function greet(name) {
            console.log(name);
          }
          ```
          :::
        MARKDOWN
      end

      it "applies line highlighting classes" do
        result = processor.preprocess(content)

        expect(result).to include("docyard-code-line--highlighted")
      end
    end

    context "with line numbers" do
      let(:content) do
        <<~MARKDOWN
          :::code-group
          ```js [JavaScript]:line-numbers
          const a = 1;
          const b = 2;
          ```
          :::
        MARKDOWN
      end

      it "renders line numbers", :aggregate_failures do
        result = processor.preprocess(content)

        expect(result).to include("docyard-code-block__lines")
        expect(result).to include("docyard-code-block--line-numbers")
      end
    end

    context "with diff markers" do
      let(:content) do
        <<~MARKDOWN
          :::code-group
          ```js [JavaScript]
          const old = 1; // [!code --]
          const new = 2; // [!code ++]
          ```
          :::
        MARKDOWN
      end

      it "applies diff line classes", :aggregate_failures do
        result = processor.preprocess(content)

        expect(result).to include("docyard-code-line--diff-add")
        expect(result).to include("docyard-code-line--diff-remove")
      end
    end

    context "with language icons" do
      let(:content) do
        <<~MARKDOWN
          :::code-group
          ```ruby [Ruby]
          puts "hello"
          ```
          :::
        MARKDOWN
      end

      it "includes language icon in tab" do
        result = processor.preprocess(content)

        expect(result).to include("docyard-icon")
      end
    end

    context "with copy button" do
      let(:content) do
        <<~MARKDOWN
          :::code-group
          ```js [Test]
          const code = "test";
          ```
          :::
        MARKDOWN
      end

      it "includes copy button in header", :aggregate_failures do
        result = processor.preprocess(content)

        expect(result).to include("docyard-code-group__copy")
        expect(result).to include('aria-label="Copy code to clipboard"')
      end

      it "stores code text in panel data attribute" do
        result = processor.preprocess(content)

        expect(result).to include('data-code="const code = &quot;test&quot;;"')
      end
    end
  end
end
