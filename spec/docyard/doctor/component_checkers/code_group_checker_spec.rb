# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::CodeGroupChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid code-group" do
    content = ":::code-group\n```js [app.js]\ncode\n```\n```rb [app.rb]\ncode\n```\n:::"

    expect(check(content)).to be_empty
  end

  it "detects empty code-group block", :aggregate_failures do
    diagnostics = check(":::code-group\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CODE_GROUP_EMPTY")
    expect(diagnostics.first.message).to include("empty code-group")
  end

  it "detects unclosed code-group block", :aggregate_failures do
    diagnostics = check(":::code-group\n```js [app.js]\ncode\n```")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CODE_GROUP_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
  end

  it "detects code block missing label", :aggregate_failures do
    content = ":::code-group\n```js [labeled.js]\ncode\n```\n```ruby\ncode\n```\n:::"

    diagnostics = check(content)

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CODE_GROUP_MISSING_LABEL")
    expect(diagnostics.first.message).to include("missing label")
  end
end
