# frozen_string_literal: true

require "benchmark"

RSpec.describe Docyard::Components::TabsProcessor do
  let(:processor) { described_class.new }

  describe ".priority" do
    it "has the correct priority" do
      expect(described_class.priority).to eq(15)
    end
  end

  describe "#preprocess" do
    context "with valid tabs syntax" do
      it "converts basic tabs with two tabs", :aggregate_failures do
        markdown = ":::tabs\n== npm\n```bash\nnpm install docyard\n```\n\n== yarn\n```bash\nyarn add docyard\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-tabs"', 'role="tablist"', "npm", "yarn", "install", "docyard", "add")
      end

      it "converts tabs with multiple package managers", :aggregate_failures do
        markdown = ":::tabs\n== npm\nnpm install\n\n== yarn\nyarn add\n\n== pnpm\npnpm add\n\n== bun\nbun add\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("npm")
        expect(result).to include("yarn")
        expect(result).to include("pnpm")
        expect(result).to include("bun")
      end

      it "processes markdown content inside tabs", :aggregate_failures do
        markdown = ":::tabs\n== Tab 1\n**bold** and *italic*\n\n== Tab 2\n`code`\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("<strong>bold</strong>", "<em>italic</em>", "<code>code</code>")
      end

      it "processes code blocks with syntax highlighting", :aggregate_failures do
        md = ":::tabs\n== Ruby\n```ruby\nputs 'hi'\n```\n\n== JavaScript\n```javascript\nconsole.log('hi');\n```\n:::"
        result = processor.preprocess(md)

        expect(result).to include("language-ruby", "language-javascript", "puts", "console", "log")
      end

      it "includes proper ARIA attributes", :aggregate_failures do
        markdown = ":::tabs\n== Tab 1\nContent 1\n\n== Tab 2\nContent 2\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('role="tablist"', 'role="tab"', 'role="tabpanel"')
        expect(result).to include('aria-selected="true"', 'aria-selected="false"')
        expect(result).to include("aria-controls=", "aria-labelledby=", 'aria-hidden="false"', 'aria-hidden="true"')
      end

      it "sets first tab as active by default", :aggregate_failures do
        markdown = ":::tabs\n== First\nContent 1\n\n== Second\nContent 2\n:::"
        result = processor.preprocess(markdown)

        expect(result).to match(/role="tab"[^>]*aria-selected="true"/)
        expect(result).to match(/role="tabpanel"[^>]*aria-hidden="false"/)
      end

      it "includes tabindex attributes for keyboard navigation", :aggregate_failures do
        markdown = ":::tabs\n== Tab 1\nContent 1\n\n== Tab 2\nContent 2\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('tabindex="0"', 'tabindex="-1"')
      end

      it "wraps output in nomarkdown blocks", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Tab 1\nContent\n:::")

        expect(result).to include("{::nomarkdown}", "{:/nomarkdown}")
      end

      it "generates unique IDs for tabs and panels", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Tab 1\nContent 1\n\n== Tab 2\nContent 2\n:::")

        expect(result).to match(/id="tab-[a-f0-9]+-0"/).and match(/id="tab-[a-f0-9]+-1"/)
        expect(result).to match(/id="tabpanel-[a-f0-9]+-0"/).and match(/id="tabpanel-[a-f0-9]+-1"/)
        expect(result).to match(/aria-controls="tabpanel-[a-f0-9]+-0"/).and match(/aria-labelledby="tab-[a-f0-9]+-0"/)
      end

      it "includes list wrapper element" do
        result = processor.preprocess(":::tabs\n== Tab 1\nContent\n:::")

        expect(result).to include('class="docyard-tabs__list-wrapper"')
      end

      it "includes data-tabs attribute with group ID" do
        result = processor.preprocess(":::tabs\n== Tab 1\nContent\n:::")

        expect(result).to match(/data-tabs="[a-f0-9]+"/)
      end
    end

    context "with multiple tab groups" do
      it "handles multiple tab groups in same document", :aggregate_failures do
        markdown = ":::tabs\n== npm\nnpm install\n:::\n\nText\n\n:::tabs\n== yarn\nyarn add\n:::"
        result = processor.preprocess(markdown)

        expect(result.scan('class="docyard-tabs"').length).to eq(2)
        expect(result.scan('role="tablist"').length).to eq(2)
        expect(result).to include("npm install", "yarn add")
      end

      it "generates different group IDs for each tab group", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Tab 1\nContent 1\n:::\n\n:::tabs\n== Tab 2\nContent 2\n:::")
        group_ids = result.scan(/data-tabs="([a-f0-9]+)"/).flatten

        expect(group_ids.length).to eq(2)
        expect(group_ids.uniq.length).to eq(2)
      end
    end

    context "with edge cases" do
      it "handles empty tab content", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Empty Tab\n:::")

        expect(result).to include('class="docyard-tabs"', "Empty Tab")
      end

      it "handles tabs with only whitespace in content", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Tab 1\n\n\n== Tab 2\n\n\n:::")

        expect(result).to include('class="docyard-tabs"', "Tab 1", "Tab 2")
      end

      it "handles single tab", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Only Tab\nSingle tab content\n:::")

        expect(result).to include('class="docyard-tabs"', "Only Tab", "Single tab content")
      end

      it "handles tab names with special characters", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Node.js\nNode content\n\n== C++\nC++ content\n:::")

        expect(result).to include("Node.js", "C++")
      end

      it "preserves content outside tabs", :aggregate_failures do
        result = processor.preprocess("Regular paragraph\n\n:::tabs\n== Tab\nTab content\n:::\n\nAnother paragraph")

        expect(result).to include("Regular paragraph", "Another paragraph")
      end

      it "does not process incomplete tabs syntax" do
        markdown = ":::tabs\n== Tab\nNo closing tag"
        result = processor.preprocess(markdown)

        expect(result).to eq(markdown)
      end

      it "handles tabs without any tab sections" do
        markdown = <<~MD
          :::tabs
          Content without tab markers
          :::
        MD

        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-tabs"')
      end

      it "returns content unchanged if no tabs syntax present" do
        markdown = "Regular markdown content\nNo tabs here"
        result = processor.preprocess(markdown)

        expect(result).to eq(markdown)
      end
    end

    context "with complex markdown content" do
      it "handles lists inside tabs", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Tab 1\n- Item 1\n- Item 2\n\n== Tab 2\n1. First\n2. Second\n:::")

        expect(result).to include("<ul>", "<li>Item 1</li>", "<ol>", "<li>First</li>")
      end

      it "handles headings inside tabs", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Tab 1\n### Heading\nContent\n\n== Tab 2\n#### Another\nMore\n:::")

        expect(result).to include("<h3", "Heading", "<h4", "Another")
      end

      it "handles links inside tabs", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Tab 1\n[example](https://example.com)\n\n== Tab 2\n[link](https://test.com)\n:::")

        expect(result).to include('<a href="https://example.com"', '<a href="https://test.com"', "example", "link")
      end

      it "handles images inside tabs", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Tab 1\n![Alt text](image.png)\n:::")

        expect(result).to include("<img", 'src="image.png"', 'alt="Alt text"')
      end

      it "handles blockquotes inside tabs", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Tab 1\n> This is a quote\n> Continued\n:::")

        expect(result).to include("<blockquote>", "This is a quote")
      end

      it "handles tables inside tabs", :aggregate_failures do
        result = processor.preprocess(":::tabs\n== Tab 1\n| Header 1 | Header 2 |\n|---|---|\n| Cell 1 | Cell 2 |\n:::")

        expect(result).to include("<table>", "<thead>", "<tbody>", "Header 1", "Cell 1")
      end

      it "handles multiple paragraphs inside tabs", :aggregate_failures do
        md = ":::tabs\n== Tab 1\nFirst paragraph.\n\nSecond paragraph.\n\nThird paragraph.\n:::"
        result = processor.preprocess(md)

        expect(result).to include("First paragraph", "Second paragraph", "Third paragraph")
      end
    end
  end

  describe "icon functionality" do
    context "with manual icon syntax" do
      it "extracts icon from tab name with :icon-name: syntax", :aggregate_failures do
        markdown = ":::tabs\n== :package: npm\n```bash\nnpm install\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-tabs__icon"')
        expect(result).to include('viewBox="0 0 256 256"')
        expect(result).to match(%r{>\s*npm\s*</button>}m)
      end

      it "handles multiple tabs with different manual icons", :aggregate_failures do
        markdown = ":::tabs\n== :package: npm\nnpm install\n\n== :cube: yarn\nyarn add\n\n" \
                   "== :rocket: Quick Start\nGet started quickly\n:::"
        result = processor.preprocess(markdown)

        expect(result.scan('class="docyard-tabs__icon"').length).to eq(3)
        expect(result).to match(%r{>\s*npm\s*</button>}m)
        expect(result).to match(%r{>\s*yarn\s*</button>}m)
        expect(result).to match(%r{>\s*Quick Start\s*</button>}m)
      end

      it "preserves icon name in icon data", :aggregate_failures do
        markdown = ":::tabs\n== :star: Featured\nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("star")
        expect(result).to match(%r{>\s*Featured\s*</button>}m)
      end

      it "handles icon names with hyphens", :aggregate_failures do
        markdown = ":::tabs\n== :arrow-right: Next Step\nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("arrow-right")
        expect(result).to match(%r{>\s*Next Step\s*</button>}m)
      end

      it "manual icon takes precedence over auto-detection", :aggregate_failures do
        markdown = ":::tabs\n== :star: Featured\n```javascript\nconsole.log();\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("star")
        expect(result).to include('viewBox="0 0 256 256"')
      end
    end

    context "with auto-detected icons for code-only tabs" do
      it "detects terminal commands (bash)", :aggregate_failures do
        markdown = ":::tabs\n== Install\n```bash\nnpm install docyard\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-tabs__icon"')
        expect(result).to include("terminal-window")
        expect(result).to include('viewBox="0 0 256 256"')
      end

      it "detects terminal commands (sh)", :aggregate_failures do
        markdown = ":::tabs\n== Script\n```sh\necho 'test'\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-tabs__icon"')
        expect(result).to include("terminal-window")
      end

      it "detects file extension for JavaScript", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```javascript\nconsole.log('test');\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-tabs__icon"')
        expect(result).to include("file")
      end

      it "detects file extension for TypeScript", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```typescript\nconst x: number = 1;\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-tabs__icon"')
        expect(result).to include("file")
      end

      it "detects file extension for Python", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```python\nprint('test')\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-tabs__icon"')
        expect(result).to include("file")
      end
    end

    context "with language alias mapping to file extensions" do
      it "maps js to .js extension", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```js\nconst x = 1;\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("file")
      end

      it "maps ts to .ts extension", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```ts\nconst x: number = 1;\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("file")
      end

      it "maps py to .py extension", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```py\nx = 1\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("file")
      end

      it "maps rb to .rb extension", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```rb\nx = 1\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("file")
      end

      it "maps shell commands to terminal-window (Phosphor)", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```sh\necho test\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("terminal-window")
        expect(result).to include('viewBox="0 0 256 256"')
      end

      it "maps bash to terminal-window (Phosphor)", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```bash\necho test\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("terminal-window")
        expect(result).to include('viewBox="0 0 256 256"')
      end

      it "maps html to .html extension", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```html\n<div></div>\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("file")
      end

      it "maps yml to .yaml extension", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```yml\nkey: value\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("file")
      end
    end

    context "with no icon for mixed or plain content" do
      it "shows NO icon when tab has plain text (no code)", :aggregate_failures do
        markdown = ":::tabs\n== Overview\nJust regular text content\n:::"
        result = processor.preprocess(markdown)

        expect(result).not_to include('class="docyard-tabs__icon"')
      end
    end

    context "with fallback behavior for unknown languages" do
      it "uses fallback file icon for unrecognized language", :aggregate_failures do
        markdown = ":::tabs\n== Code\n```unknownlang\nsome code\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include('class="docyard-tabs__icon"')
        expect(result).to include("file")
        expect(result).to include('viewBox="0 0 256 256"')
      end
    end

    context "with edge cases" do
      it "handles invalid icon syntax (missing closing colon)", :aggregate_failures do
        markdown = ":::tabs\n== :package Tab Name\nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include(":package Tab Name")
      end

      it "handles empty icon name", :aggregate_failures do
        markdown = ":::tabs\n== :: Tab Name\nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include(":: Tab Name")
      end

      it "handles tab with mixed content (code and text) - NO icon", :aggregate_failures do
        markdown = ":::tabs\n== Tab\nSome text\n\n```javascript\ncode();\n```\n\nMore text\n:::"
        result = processor.preprocess(markdown)

        expect(result).not_to include('class="docyard-tabs__icon"')
      end

      it "handles tab with multiple code blocks - NO icon", :aggregate_failures do
        markdown = ":::tabs\n== Tab\n```javascript\njs code\n```\n\n```python\npy code\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).not_to include('class="docyard-tabs__icon"')
      end

      it "handles code block at the end of mixed content - NO icon", :aggregate_failures do
        markdown = ":::tabs\n== Tab\nIntro text here\n\n```ruby\nputs 'hi'\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).not_to include('class="docyard-tabs__icon"')
      end

      it "is case insensitive for language detection", :aggregate_failures do
        markdown = ":::tabs\n== Tab\n```JavaScript\nconsole.log();\n```\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("file")
      end

      it "handles whitespace around icon syntax", :aggregate_failures do
        markdown = ":::tabs\n== :package:   Tab Name\nContent\n:::"
        result = processor.preprocess(markdown)

        expect(result).to include("package")
        expect(result).to match(%r{>\s*Tab Name\s*</button>}m)
      end
    end

    context "with all supported file extensions and terminal" do
      it "supports common programming languages (currently shows file icon)", :aggregate_failures do
        languages = %w[javascript typescript python ruby go rust php html css json yaml toml sql graphql]

        languages.each do |lang|
          markdown = ":::tabs\n== Code\n```#{lang}\ncode\n```\n:::"
          result = processor.preprocess(markdown)

          expect(result).to include('class="docyard-tabs__icon"'), "Expected icon for #{lang}"
          expect(result).to include("file"), "Expected file icon for #{lang}"
        end
      end

      it "supports terminal commands with terminal-window icon", :aggregate_failures do
        shell_langs = %w[bash sh shell]

        shell_langs.each do |shell|
          markdown = ":::tabs\n== Command\n```#{shell}\necho test\n```\n:::"
          result = processor.preprocess(markdown)

          expect(result).to include('class="docyard-tabs__icon"'), "Expected icon for #{shell}"
          expect(result).to include("terminal-window"), "Expected terminal-window icon for #{shell}"
          expect(result).to include('viewBox="0 0 256 256"'), "Expected Phosphor viewBox for #{shell}"
        end
      end
    end
  end

  describe "accessibility" do
    it "uses semantic HTML roles", :aggregate_failures do
      markdown = <<~MD
        :::tabs
        == Tab 1
        Content
        :::
      MD

      result = processor.preprocess(markdown)

      expect(result).to include('role="tablist"')
      expect(result).to include('role="tab"')
      expect(result).to include('role="tabpanel"')
    end

    it "properly associates tabs with panels via ARIA", :aggregate_failures do
      result = processor.preprocess(":::tabs\n== Tab 1\nContent 1\n\n== Tab 2\nContent 2\n:::")

      expect(result).to include("aria-controls=", "aria-labelledby=")
    end

    it "includes wrapper for scroll indicators" do
      markdown = <<~MD
        :::tabs
        == Tab
        Content
        :::
      MD

      result = processor.preprocess(markdown)

      expect(result).to include('class="docyard-tabs__list-wrapper"')
    end
  end

  describe "performance" do
    it "handles large number of tabs efficiently", :aggregate_failures do
      tabs_content = (1..20).map { |i| "== Tab #{i}\nContent #{i}\n" }.join("\n")
      markdown = ":::tabs\n#{tabs_content}:::"

      result = nil
      time = Benchmark.measure do
        result = processor.preprocess(markdown)
      end

      expect(result).to include('class="docyard-tabs"')
      expect(time.real).to be < 1.0
    end

    it "handles large content inside tabs efficiently", :aggregate_failures do
      large_content = "This is a line.\n" * 1000
      markdown = ":::tabs\n== Tab 1\n#{large_content}:::"
      result = nil
      time = Benchmark.measure { result = processor.preprocess(markdown) }

      expect(result).to include('class="docyard-tabs"')
      expect(time.real).to be < 1.0
    end
  end
end
