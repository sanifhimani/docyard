# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::TabsChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid tabs" do
    expect(check(":::tabs\n== Tab 1\nContent\n== Tab 2\nMore content\n:::")).to be_empty
  end

  it "detects empty tabs block", :aggregate_failures do
    diagnostics = check(":::tabs\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("TABS_EMPTY")
    expect(diagnostics.first.message).to include("Tab Name")
  end

  it "detects unclosed tabs block", :aggregate_failures do
    diagnostics = check(":::tabs\n== Tab 1\nContent")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("TABS_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
  end
end
