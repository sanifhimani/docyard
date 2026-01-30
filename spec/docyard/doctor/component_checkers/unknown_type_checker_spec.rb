# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::UnknownTypeChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "detects unknown type with suggestion", :aggregate_failures do
    diagnostics = check(":::nite\nThis looks like a typo.\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("COMPONENT_UNKNOWN_TYPE")
    expect(diagnostics.first.message).to include("did you mean ':::note'")
  end

  it "detects unknown type without suggestion for unrecognizable type" do
    diagnostics = check(":::foobar\nUnknown type.\n:::")

    expect(diagnostics.first.message).to eq("unknown component ':::foobar'")
  end

  it "does not report known component types as unknown" do
    expect(check(":::tabs\n== Tab 1\nContent\n:::")).to be_empty
  end

  it "detects :::tab typo and suggests :::tabs", :aggregate_failures do
    diagnostics = check(":::tab\n== Tab 1\nContent\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("COMPONENT_UNKNOWN_TYPE")
    expect(diagnostics.first.message).to include("did you mean ':::tabs'")
  end
end
