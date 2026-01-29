# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::DetailsChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid details" do
    expect(check(":::details{title=\"Title\"}\nContent\n:::")).to be_empty
  end

  it "allows details with open attribute" do
    expect(check(":::details{title=\"Title\" open}\nContent\n:::")).to be_empty
  end

  it "allows details without attributes" do
    expect(check(":::details\nContent\n:::")).to be_empty
  end

  it "detects unclosed details block", :aggregate_failures do
    diagnostics = check(":::details{title=\"Title\"}\nContent")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("DETAILS_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
  end

  it "detects unknown details attribute", :aggregate_failures do
    diagnostics = check(":::details{name=\"Invalid\"}\nContent\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("DETAILS_UNKNOWN_ATTR")
    expect(diagnostics.first.message).to include("unknown details attribute 'name'")
  end

  it "suggests correct attribute for typo", :aggregate_failures do
    diagnostics = check(":::details{titl=\"Typo\"}\nContent\n:::")

    expect(diagnostics.first.message).to include("did you mean 'title'")
  end
end
