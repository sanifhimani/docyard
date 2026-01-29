# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::CodeGroupChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid code-group" do
    content = ":::code-group\n```js [app.js]\ncode\n```\n```rb [app.rb]\ncode\n```\n:::"
    write_page("guide.md", content)

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects empty code-group block", :aggregate_failures do
    write_page("guide.md", ":::code-group\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CODE_GROUP_EMPTY")
    expect(diagnostics.first.message).to include("empty code-group")
  end

  it "detects unclosed code-group block", :aggregate_failures do
    write_page("guide.md", ":::code-group\n```js [app.js]\ncode\n```")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CODE_GROUP_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
  end

  it "detects code block missing label", :aggregate_failures do
    content = ":::code-group\n```js [labeled.js]\ncode\n```\n```ruby\ncode\n```\n:::"
    write_page("guide.md", content)

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CODE_GROUP_MISSING_LABEL")
    expect(diagnostics.first.message).to include("missing label")
  end
end
