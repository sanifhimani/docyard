# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::CardsChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid cards" do
    write_page("guide.md", ":::cards\n::card{title=\"Card 1\"}\nContent\n::card{title=\"Card 2\"}\nMore content\n:::")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects empty cards block", :aggregate_failures do
    write_page("guide.md", ":::cards\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CARDS_EMPTY")
    expect(diagnostics.first.message).to include("::card{title=")
  end

  it "detects unclosed cards block", :aggregate_failures do
    write_page("guide.md", ":::cards\n::card{title=\"Card 1\"}\nContent")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CARDS_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
  end

  it "detects unknown card attribute", :aggregate_failures do
    write_page("guide.md", ":::cards\n::card{name=\"Invalid\"}\nContent\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("CARD_UNKNOWN_ATTR")
    expect(diagnostics.first.message).to include("unknown card attribute 'name'")
  end

  it "suggests correct attribute for typo", :aggregate_failures do
    write_page("guide.md", ":::cards\n::card{titl=\"Typo\"}\nContent\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.message).to include("did you mean 'title'")
  end

  it "accepts valid card attributes" do
    write_page("guide.md", ":::cards\n::card{title=\"Card\" icon=\"star\" href=\"/link\"}\nContent\n:::")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end
end
