# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::StepsChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid steps" do
    expect(check(":::steps\n### Step 1\nDo this first.\n### Step 2\nThen this.\n:::")).to be_empty
  end

  it "detects empty steps block", :aggregate_failures do
    diagnostics = check(":::steps\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("STEPS_EMPTY")
    expect(diagnostics.first.message).to include("### Step Title")
  end

  it "detects unclosed steps block", :aggregate_failures do
    diagnostics = check(":::steps\n### Step 1\nContent")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("STEPS_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
  end
end
