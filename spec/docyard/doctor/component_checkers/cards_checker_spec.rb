# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::CardsChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid cards" do
    content = ":::cards\n::card{title=\"Card 1\"}\nContent\n::card{title=\"Card 2\"}\nMore content\n:::"

    expect(check(content)).to be_empty
  end

  it "detects empty cards block", :aggregate_failures do
    diagnostics = check(":::cards\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CARDS_EMPTY")
    expect(diagnostics.first.message).to include("::card{title=")
  end

  it "detects unclosed cards block", :aggregate_failures do
    diagnostics = check(":::cards\n::card{title=\"Card 1\"}\nContent")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CARDS_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
  end

  it "detects unknown card attribute", :aggregate_failures do
    diagnostics = check(":::cards\n::card{name=\"Invalid\"}\nContent\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CARD_UNKNOWN_ATTR")
    expect(diagnostics.first.message).to include("unknown card attribute 'name'")
  end

  it "suggests correct attribute for typo", :aggregate_failures do
    diagnostics = check(":::cards\n::card{titl=\"Typo\"}\nContent\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.message).to include("did you mean 'title'")
  end

  it "accepts valid card attributes" do
    content = ":::cards\n::card{title=\"Card\" icon=\"star\" href=\"/link\"}\nContent\n:::"

    expect(check(content)).to be_empty
  end
end
