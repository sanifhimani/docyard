# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::CalloutChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid callout" do
    expect(check(":::note\nThis is a note.\n:::")).to be_empty
  end

  it "detects unclosed callout block", :aggregate_failures do
    diagnostics = check(":::warning\nThis block is never closed.")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CALLOUT_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
    expect(diagnostics.first.line).to eq(1)
  end

  it "detects empty callout block", :aggregate_failures do
    diagnostics = check(":::tip\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CALLOUT_EMPTY")
    expect(diagnostics.first.message).to include("empty")
  end

  it "ignores callouts inside code blocks" do
    content = "```markdown\n:::foobar\nExample.\n:::\n```"

    expect(check(content)).to be_empty
  end

  %w[note tip important warning danger].each do |type|
    it "accepts valid callout type '#{type}'" do
      expect(check(":::#{type}\nContent.\n:::")).to be_empty
    end
  end
end
