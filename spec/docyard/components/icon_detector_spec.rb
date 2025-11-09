# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Components::IconDetector do
  describe ".detect" do
    context "with manual icon syntax" do
      it "extracts icon name from :icon-name: syntax" do
        tab_name = ":rocket: Launch"
        tab_content = "Some content"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Launch",
            icon: "rocket",
            icon_source: "phosphor"
          }
        )
      end

      it "handles icon names with hyphens" do
        tab_name = ":rocket-launch: Deploy"
        tab_content = "Some content"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Deploy",
            icon: "rocket-launch",
            icon_source: "phosphor"
          }
        )
      end

      it "handles icon names with numbers" do
        tab_name = ":icon123: Test"
        tab_content = "Some content"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Test",
            icon: "icon123",
            icon_source: "phosphor"
          }
        )
      end

      it "is case insensitive for icon names" do
        tab_name = ":RoCkEt: Launch"
        tab_content = "Some content"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Launch",
            icon: "RoCkEt",
            icon_source: "phosphor"
          }
        )
      end

      it "strips whitespace from extracted tab name" do
        tab_name = ":rocket:   Launch   "
        tab_content = "Some content"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Launch",
            icon: "rocket",
            icon_source: "phosphor"
          }
        )
      end

      it "manual icon takes precedence over auto-detection" do
        tab_name = ":rocket: JavaScript"
        tab_content = "```javascript\nconst foo = 'bar';\n```"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "JavaScript",
            icon: "rocket",
            icon_source: "phosphor"
          }
        )
      end
    end

    context "with auto-detected icons from code" do
      it "detects JavaScript icon from code-only content" do
        tab_name = "JavaScript"
        tab_content = "```javascript\nconst foo = 'bar';\n```"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "JavaScript",
            icon: "js",
            icon_source: "file-extension"
          }
        )
      end

      it "detects TypeScript icon from code-only content" do
        tab_name = "TypeScript"
        tab_content = "```typescript\nlet x: string = 'hello';\n```"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "TypeScript",
            icon: "ts",
            icon_source: "file-extension"
          }
        )
      end

      it "detects Python icon from code-only content" do
        tab_name = "Python"
        tab_content = "```python\nprint('hello')\n```"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Python",
            icon: "py",
            icon_source: "file-extension"
          }
        )
      end

      it "detects terminal icon from bash code" do
        tab_name = "Install"
        tab_content = "```bash\nnpm install\n```"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Install",
            icon: "terminal-window",
            icon_source: "phosphor"
          }
        )
      end

      it "detects terminal icon from sh code" do
        tab_name = "Setup"
        tab_content = "```sh\nls -la\n```"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Setup",
            icon: "terminal-window",
            icon_source: "phosphor"
          }
        )
      end

      it "detects file icon for unknown language" do
        tab_name = "Unknown"
        tab_content = "```unknown\nsome code\n```"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Unknown",
            icon: "file",
            icon_source: "phosphor"
          }
        )
      end
    end

    context "with no icon for mixed or plain content" do
      it "returns nil icon for plain text content" do
        tab_name = "Overview"
        tab_content = "This is just plain text without any code blocks."

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Overview",
            icon: nil,
            icon_source: nil
          }
        )
      end

      it "returns nil icon for mixed content (code + text)" do
        tab_name = "Tutorial"
        tab_content = "Here's some code:\n```javascript\nconst foo = 'bar';\n```\nAnd here's more explanation."

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Tutorial",
            icon: nil,
            icon_source: nil
          }
        )
      end

      it "returns nil icon for multiple code blocks" do
        tab_name = "Examples"
        tab_content = "```javascript\nconst foo = 'bar';\n```\n```python\nprint('hello')\n```"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Examples",
            icon: nil,
            icon_source: nil
          }
        )
      end

      it "returns nil icon for empty content" do
        tab_name = "Empty"
        tab_content = ""

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Empty",
            icon: nil,
            icon_source: nil
          }
        )
      end
    end

    context "with invalid manual icon syntax" do
      it "returns nil icon when missing closing colon" do
        tab_name = ":rocket Launch"
        tab_content = "Some content"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: ":rocket Launch",
            icon: nil,
            icon_source: nil
          }
        )
      end

      it "returns nil icon when missing opening colon" do
        tab_name = "rocket: Launch"
        tab_content = "Some content"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "rocket: Launch",
            icon: nil,
            icon_source: nil
          }
        )
      end

      it "returns nil icon when icon name is empty" do
        tab_name = ":: Launch"
        tab_content = "Some content"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: ":: Launch",
            icon: nil,
            icon_source: nil
          }
        )
      end

      it "returns nil icon when only opening colon exists" do
        tab_name = ":Launch"
        tab_content = "Some content"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: ":Launch",
            icon: nil,
            icon_source: nil
          }
        )
      end
    end

    context "with edge cases" do
      it "preserves tab name whitespace when auto-detecting" do
        tab_name = "   JavaScript   "
        tab_content = "```javascript\nconst foo = 'bar';\n```"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "   JavaScript   ",
            icon: "js",
            icon_source: "file-extension"
          }
        )
      end

      it "handles tab content with whitespace only" do
        tab_name = "Empty"
        tab_content = "   \n  \n  "

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "Empty",
            icon: nil,
            icon_source: nil
          }
        )
      end

      it "handles special characters in tab name" do
        tab_name = "C++"
        tab_content = "```cpp\nint main() {}\n```"

        result = described_class.detect(tab_name, tab_content)

        expect(result).to eq(
          {
            name: "C++",
            icon: "file",
            icon_source: "phosphor"
          }
        )
      end
    end
  end
end
