# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeSnippetImportPreprocessor do
  include_context "with temp directory"

  let(:docs_dir) { File.join(temp_dir, "docs") }
  let(:processor) { described_class.new(context) }
  let(:context) { { docs_root: docs_dir } }

  before do
    FileUtils.mkdir_p(docs_dir)
  end

  describe "#preprocess" do
    context "with basic file import" do
      before do
        File.write(File.join(docs_dir, "example.js"), <<~JS)
          function hello() {
            console.log("Hello, World!");
          }
        JS
      end

      it "imports the file content", :aggregate_failures do
        content = "<<< @/example.js"
        result = processor.preprocess(content)

        expect(result).to include("```javascript")
        expect(result).to include('console.log("Hello, World!")')
        expect(result).to include("```")
      end

      it "adds filename as title" do
        content = "<<< @/example.js"
        result = processor.preprocess(content)

        expect(result).to include("[example.js]")
      end
    end

    context "with nested file paths" do
      before do
        FileUtils.mkdir_p(File.join(docs_dir, "src", "utils"))
        File.write(File.join(docs_dir, "src", "utils", "helper.rb"), <<~RUBY)
          def helper
            puts "I help"
          end
        RUBY
      end

      it "imports from nested paths", :aggregate_failures do
        content = "<<< @/src/utils/helper.rb"
        result = processor.preprocess(content)

        expect(result).to include("```ruby")
        expect(result).to include("def helper")
      end
    end

    context "with line highlighting" do
      before do
        File.write(File.join(docs_dir, "example.py"), <<~PYTHON)
          def add(a, b):
              return a + b

          def subtract(a, b):
              return a - b
        PYTHON
      end

      it "passes through line highlights" do
        content = "<<< @/example.py{2,4}"
        result = processor.preprocess(content)

        expect(result).to include("```python [example.py] {2,4}")
      end
    end

    context "with language override" do
      before do
        File.write(File.join(docs_dir, "config"), <<~CONFIG)
          server {
            listen 80;
          }
        CONFIG
      end

      it "uses specified language" do
        content = "<<< @/config{nginx}"
        result = processor.preprocess(content)

        expect(result).to include("```nginx")
      end

      it "combines highlights and language" do
        content = "<<< @/config{1-2 nginx}"
        result = processor.preprocess(content)

        expect(result).to include("```nginx")
      end
    end

    context "with VS Code regions" do
      before do
        File.write(File.join(docs_dir, "regions.js"), <<~JS)
          // Some setup code
          const config = {};

          // #region helper-functions
          function helper1() {
            return 1;
          }

          function helper2() {
            return 2;
          }
          // #endregion helper-functions

          // More code
          export default config;
        JS
      end

      it "extracts the named region", :aggregate_failures do
        content = "<<< @/regions.js#helper-functions"
        result = processor.preprocess(content)

        expect(result).to include("function helper1()")
        expect(result).to include("function helper2()")
        expect(result).not_to include("const config")
        expect(result).not_to include("export default")
        expect(result).not_to include("#region")
      end
    end

    context "with Python-style regions" do
      before do
        File.write(File.join(docs_dir, "regions.py"), <<~PYTHON)
          import os

          # #region utilities
          def util_one():
              pass

          def util_two():
              pass
          # #endregion utilities

          def main():
              pass
        PYTHON
      end

      it "extracts Python regions", :aggregate_failures do
        content = "<<< @/regions.py#utilities"
        result = processor.preprocess(content)

        expect(result).to include("def util_one():")
        expect(result).to include("def util_two():")
        expect(result).not_to include("import os")
        expect(result).not_to include("def main():")
      end
    end

    context "with non-existent file" do
      it "returns an error message", :aggregate_failures do
        content = "<<< @/missing.js"
        result = processor.preprocess(content)

        expect(result).to include("Error importing")
        expect(result).to include("File not found")
      end
    end

    context "with non-existent region" do
      before do
        File.write(File.join(docs_dir, "example.js"), "const x = 1;")
      end

      it "returns an error message", :aggregate_failures do
        content = "<<< @/example.js#nonexistent"
        result = processor.preprocess(content)

        expect(result).to include("Error importing")
        expect(result).to include("Region 'nonexistent' not found")
      end
    end

    context "with multiple imports in content" do
      before do
        File.write(File.join(docs_dir, "file1.js"), "const a = 1;")
        File.write(File.join(docs_dir, "file2.rb"), "b = 2")
      end

      it "processes all imports", :aggregate_failures do
        content = <<~MD
          # Example

          <<< @/file1.js

          Some text

          <<< @/file2.rb
        MD

        result = processor.preprocess(content)

        expect(result).to include("```javascript")
        expect(result).to include("const a = 1")
        expect(result).to include("```ruby")
        expect(result).to include("b = 2")
      end
    end

    context "with line range extraction" do
      before do
        File.write(File.join(docs_dir, "long.js"), <<~JS)
          line 1
          line 2
          line 3
          line 4
          line 5
        JS
      end

      it "extracts specified line range", :aggregate_failures do
        content = "<<< @/long.js{2-4}"
        result = processor.preprocess(content)

        expect(result).to include("line 2")
        expect(result).to include("line 3")
        expect(result).to include("line 4")
        expect(result).not_to include("line 1")
        expect(result).not_to include("line 5")
      end
    end

    context "when surrounding content exists" do
      before do
        File.write(File.join(docs_dir, "example.js"), "const x = 1;")
      end

      it "keeps text before and after import", :aggregate_failures do
        content = <<~MD
          Before the import.

          <<< @/example.js

          After the import.
        MD

        result = processor.preprocess(content)

        expect(result).to include("Before the import.")
        expect(result).to include("After the import.")
        expect(result).to include("const x = 1")
      end
    end
  end

  describe "language detection" do
    {
      "file.rb" => "ruby",
      "file.js" => "javascript",
      "file.ts" => "typescript",
      "file.py" => "python",
      "file.yml" => "yaml",
      "file.sh" => "bash",
      "file.jsx" => "jsx",
      "file.tsx" => "tsx",
      "file.go" => "go",
      "file.rs" => "rs"
    }.each do |filename, expected_lang|
      it "detects #{expected_lang} from #{filename}" do
        File.write(File.join(docs_dir, filename), "content")
        result = processor.preprocess("<<< @/#{filename}")

        expect(result).to include("```#{expected_lang}")
      end
    end
  end

  describe "code block preservation" do
    it "does not process import syntax inside code blocks", :aggregate_failures do
      File.write(File.join(docs_dir, "real.rb"), "real_code")
      content = <<~MARKDOWN
        <<< @/real.rb

        ```markdown
        <<< @/example.rb
        ```
      MARKDOWN
      result = processor.preprocess(content)

      expect(result).to include("```ruby")
      expect(result).to include("real_code")
      expect(result).to include("<<< @/example.rb")
    end
  end
end
