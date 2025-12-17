# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Components::TabsParser do
  describe ".parse" do
    context "with valid tab content" do
      it "parses a single tab", :aggregate_failures do
        content = "== Tab One\n\nContent for tab one"
        tabs = described_class.parse(content)

        expect(tabs.length).to eq(1)
        expect(tabs[0][:name]).to eq("Tab One")
        expect(tabs[0][:content]).to include("Content for tab one")
      end

      it "parses multiple tabs", :aggregate_failures do
        content = <<~CONTENT
          == Tab One
          Content for tab one

          == Tab Two
          Content for tab two
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs.length).to eq(2)
        expect(tabs[0][:name]).to eq("Tab One")
        expect(tabs[1][:name]).to eq("Tab Two")
      end

      it "parses tabs with markdown content", :aggregate_failures do
        content = "== Tab One\n# Heading\n\nParagraph with **bold** and *italic*.\n\n- List item 1\n- List item 2"
        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include("<h1", "<strong>bold</strong>", "<em>italic</em>", "<ul>", "<li>")
      end

      it "parses tabs with code blocks", :aggregate_failures do
        content = <<~CONTENT
          == JavaScript
          ```javascript
          const foo = 'bar';
          ```
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include("<div class=\"highlight\"")
        expect(tabs[0][:content]).to include("const")
      end

      it "adds copy button to code blocks inside tabs", :aggregate_failures do
        content = <<~CONTENT
          == JavaScript
          ```javascript
          const foo = 'bar';
          ```
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include('class="docyard-code-block"')
        expect(tabs[0][:content]).to include('class="docyard-code-block__copy"')
        expect(tabs[0][:content]).to include('data-code="')
      end

      it "detects icons for code-only tabs", :aggregate_failures do
        content = <<~CONTENT
          == JavaScript
          ```javascript
          const foo = 'bar';
          ```
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:icon]).to eq("js")
        expect(tabs[0][:icon_source]).to eq("file-extension")
      end

      it "detects terminal icons for bash code", :aggregate_failures do
        content = <<~CONTENT
          == Install
          ```bash
          npm install
          ```
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:icon]).to eq("terminal-window")
        expect(tabs[0][:icon_source]).to eq("phosphor")
      end

      it "detects manual icons from tab names", :aggregate_failures do
        content = <<~CONTENT
          == :rocket: Launch
          Deployment instructions
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:name]).to eq("Launch")
        expect(tabs[0][:icon]).to eq("rocket")
        expect(tabs[0][:icon_source]).to eq("phosphor")
      end

      it "sets icon to nil for mixed content", :aggregate_failures do
        content = "== Tutorial\nHere's some code:\n```javascript\nconst foo = 'bar';\n```\nAnd more text."
        tabs = described_class.parse(content)

        expect(tabs[0][:icon]).to be_nil
        expect(tabs[0][:icon_source]).to be_nil
      end
    end

    context "with empty or whitespace content" do
      it "returns empty array for empty content" do
        content = ""
        tabs = described_class.parse(content)

        expect(tabs).to eq([])
      end

      it "filters out tabs with whitespace-only names", :aggregate_failures do
        content = "==\nContent with == prefix\n\n==\nEmpty name\n\n== Valid Tab\nValid content"
        tabs = described_class.parse(content)

        # First tab name is "==", second filtered (empty name), third is "Valid Tab"
        expect(tabs.length).to eq(2)
        expect(tabs[0][:name]).to eq("==")
        expect(tabs[1][:name]).to eq("Valid Tab")
      end

      it "handles tabs with whitespace-only content", :aggregate_failures do
        content = <<~CONTENT
          == Empty Tab


        CONTENT

        tabs = described_class.parse(content)

        expect(tabs.length).to eq(1)
        expect(tabs[0][:name]).to eq("Empty Tab")
        expect(tabs[0][:content]).to eq("")
      end

      it "filters out sections with only whitespace before tab name", :aggregate_failures do
        content = <<~CONTENT

          == Tab One
          Content
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs.length).to eq(1)
        expect(tabs[0][:name]).to eq("Tab One")
      end
    end

    context "with special characters in tab names" do
      it "handles tab names with special characters" do
        content = <<~CONTENT
          == C++ Code
          Some C++ code
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:name]).to eq("C++ Code")
      end

      it "handles tab names with numbers" do
        content = <<~CONTENT
          == Step 1
          First step
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:name]).to eq("Step 1")
      end

      it "handles tab names with hyphens" do
        content = <<~CONTENT
          == Getting-Started
          Introduction
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:name]).to eq("Getting-Started")
      end

      it "handles tab names with underscores" do
        content = <<~CONTENT
          == my_tab_name
          Content
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:name]).to eq("my_tab_name")
      end
    end

    context "with complex markdown" do
      it "parses tabs with links", :aggregate_failures do
        content = <<~CONTENT
          == Tab One
          [Link text](https://example.com)
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include("<a href")
        expect(tabs[0][:content]).to include("https://example.com")
      end

      it "parses tabs with tables", :aggregate_failures do
        content = <<~CONTENT
          == Tab One
          | Header 1 | Header 2 |
          |----------|----------|
          | Cell 1   | Cell 2   |
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include("<table>")
        expect(tabs[0][:content]).to include("<th>")
        expect(tabs[0][:content]).to include("<td>")
      end

      it "parses tabs with blockquotes" do
        content = <<~CONTENT
          == Tab One
          > This is a quote
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include("<blockquote>")
      end

      it "parses tabs with inline code", :aggregate_failures do
        content = <<~CONTENT
          == Tab One
          Use the `npm install` command.
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include("<code>")
        expect(tabs[0][:content]).to include("npm install")
      end

      it "parses tabs with images", :aggregate_failures do
        content = <<~CONTENT
          == Tab One
          ![Alt text](image.png)
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include("<img")
        expect(tabs[0][:content]).to include("image.png")
      end
    end

    context "with all supported language icons" do
      {
        "JavaScript" => { lang: "javascript", icon: "js", source: "file-extension" },
        "TypeScript" => { lang: "typescript", icon: "ts", source: "file-extension" },
        "Python" => { lang: "python", icon: "py", source: "file-extension" },
        "Ruby" => { lang: "ruby", icon: "rb", source: "file-extension" },
        "Go" => { lang: "go", icon: "go", source: "file-extension" },
        "Rust" => { lang: "rust", icon: "rs", source: "file-extension" },
        "Bash" => { lang: "bash", icon: "terminal-window", source: "phosphor" },
        "Shell" => { lang: "sh", icon: "terminal-window", source: "phosphor" },
        "HTML" => { lang: "html", icon: "html", source: "file-extension" },
        "CSS" => { lang: "css", icon: "css", source: "file-extension" },
        "JSON" => { lang: "json", icon: "json", source: "file-extension" },
        "YAML" => { lang: "yaml", icon: "yaml", source: "file-extension" },
        "SQL" => { lang: "sql", icon: "sql", source: "file-extension" }
      }.each do |name, config|
        it "detects #{config[:icon]} icon for #{name}", :aggregate_failures do
          content = "== #{name}\n```#{config[:lang]}\ncode\n```"
          tabs = described_class.parse(content)

          expect(tabs[0][:icon]).to eq(config[:icon])
          expect(tabs[0][:icon_source]).to eq(config[:source])
        end
      end
    end

    context "with edge cases" do
      it "handles tabs with extra whitespace in separator", :aggregate_failures do
        content = <<~CONTENT
          ==      Tab One
          Content
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs.length).to eq(1)
        expect(tabs[0][:name]).to eq("Tab One")
      end

      it "handles tabs with trailing whitespace in names" do
        content = <<~CONTENT
          == Tab One
          Content
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:name]).to eq("Tab One")
      end

      it "handles tabs with leading whitespace in content" do
        content = <<~CONTENT
          == Tab One
              Indented content
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include("Indented content")
      end

      it "handles very long tab names" do
        long_name = "A" * 100
        content = "== #{long_name}\nContent"
        tabs = described_class.parse(content)

        expect(tabs[0][:name]).to eq(long_name)
      end

      it "handles very long content" do
        long_content = "Word " * 1000
        content = "== Tab\n#{long_content}"
        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include("Word")
      end
    end

    context "with malformed input" do
      it "handles content without tab separator", :aggregate_failures do
        content = "Just some content without tabs"
        tabs = described_class.parse(content)

        # Content without "==" separator gets treated as a single tab name with no content
        expect(tabs.length).to eq(1)
        expect(tabs[0][:name]).to eq("Just some content without tabs")
        expect(tabs[0][:content]).to eq("")
      end

      it "handles tab separator at the very beginning", :aggregate_failures do
        content = "== First Tab\nContent"
        tabs = described_class.parse(content)

        expect(tabs.length).to eq(1)
        expect(tabs[0][:name]).to eq("First Tab")
      end

      it "handles multiple consecutive separators" do
        content = <<~CONTENT
          == Tab One
          Content

          ====

          == Tab Two
          More content
        CONTENT

        tabs = described_class.parse(content)

        # Should filter out invalid tabs
        expect(tabs.all? { |tab| !tab[:name].nil? && !tab[:name].empty? }).to be true
      end
    end

    context "with code block features" do
      it "processes focus markers inside tabs", :aggregate_failures do
        content = <<~CONTENT
          == JavaScript
          ```javascript
          const x = 1;
          const y = 2;  // [!code focus]
          ```
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include('docyard-code-block--has-focus')
        expect(tabs[0][:content]).to include('docyard-code-line--focus')
        expect(tabs[0][:content]).not_to include('[!code focus]')
      end

      it "processes diff markers inside tabs", :aggregate_failures do
        content = <<~CONTENT
          == JavaScript
          ```javascript
          const old = 1;  // [!code --]
          const new = 2;  // [!code ++]
          ```
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include('docyard-code-block--diff')
        expect(tabs[0][:content]).to include('docyard-code-line--diff-add')
        expect(tabs[0][:content]).to include('docyard-code-line--diff-remove')
        expect(tabs[0][:content]).not_to include('[!code ++]')
        expect(tabs[0][:content]).not_to include('[!code --]')
      end

      it "processes line highlights inside tabs", :aggregate_failures do
        content = <<~CONTENT
          == JavaScript
          ```javascript {2}
          const x = 1;
          const y = 2;
          const z = 3;
          ```
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include('docyard-code-block--highlighted')
        expect(tabs[0][:content]).to include('docyard-code-line--highlighted')
      end

      it "processes line numbers inside tabs", :aggregate_failures do
        content = <<~CONTENT
          == JavaScript
          ```javascript:line-numbers
          const x = 1;
          const y = 2;
          ```
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include('docyard-code-block--line-numbers')
        expect(tabs[0][:content]).to include('docyard-code-block__lines')
      end

      it "processes titles inside tabs", :aggregate_failures do
        content = <<~CONTENT
          == JavaScript
          ```javascript [utils/helper.js]
          const x = 1;
          ```
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include('docyard-code-block--titled')
        expect(tabs[0][:content]).to include('docyard-code-block__title')
        expect(tabs[0][:content]).to include('utils/helper.js')
      end

      it "processes focus markers with Python comment style", :aggregate_failures do
        content = <<~CONTENT
          == Python
          ```python
          x = 1
          y = 2  # [!code focus]
          ```
        CONTENT

        tabs = described_class.parse(content)

        expect(tabs[0][:content]).to include('docyard-code-line--focus')
        expect(tabs[0][:content]).not_to include('[!code focus]')
      end

      it "processes combined features inside tabs", :aggregate_failures do
        content = <<~CONTENT
          == TypeScript
          ```typescript [config.ts]:line-numbers {1}
          const x = 1;
          const y = 2;  // [!code focus]
          const z = 3;  // [!code ++]
          ```
        CONTENT

        tabs = described_class.parse(content)
        tab_content = tabs[0][:content]

        expect(tab_content).to include('docyard-code-block--titled')
        expect(tab_content).to include('docyard-code-block--line-numbers')
        expect(tab_content).to include('docyard-code-block--highlighted')
        expect(tab_content).to include('docyard-code-block--has-focus')
        expect(tab_content).to include('docyard-code-block--diff')
        expect(tab_content).to include('config.ts')
      end

      it "processes multiple code blocks with different features in same tab", :aggregate_failures do
        content = <<~CONTENT
          == Examples
          First code:
          ```js
          const x = 1;  // [!code focus]
          ```

          Second code:
          ```py
          y = 2  # [!code ++]
          ```
        CONTENT

        tabs = described_class.parse(content)
        tab_content = tabs[0][:content]

        expect(tab_content.scan('docyard-code-block').length).to be >= 2
        expect(tab_content).to include('docyard-code-line--focus')
        expect(tab_content).to include('docyard-code-line--diff-add')
      end
    end
  end
end
