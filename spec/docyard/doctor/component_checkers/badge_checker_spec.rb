# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::BadgeChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid badges" do
    write_page("guide.md", <<~MD)
      :badge[New]
      :badge[Beta]{type="warning"}
      :badge[Stable]{type="success"}
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects unknown badge type", :aggregate_failures do
    write_page("guide.md", ":badge[Status]{type=\"info\"}")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("BADGE_UNKNOWN_TYPE")
    expect(diagnostics.first.message).to include("unknown badge type 'info'")
  end

  it "detects unknown badge attribute", :aggregate_failures do
    write_page("guide.md", ":badge[Status]{color=\"red\"}")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("BADGE_UNKNOWN_ATTR")
    expect(diagnostics.first.message).to include("unknown badge attribute 'color'")
  end

  it "suggests valid type when typo detected" do
    write_page("guide.md", ":badge[Status]{type=\"sucess\"}")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.first.message).to include("did you mean 'success'?")
  end

  it "detects multiple issues on same line", :aggregate_failures do
    write_page("guide.md", ":badge[A]{type=\"info\"} :badge[B]{color=\"blue\"}")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(2)
    expect(diagnostics.map(&:code)).to contain_exactly("BADGE_UNKNOWN_TYPE", "BADGE_UNKNOWN_ATTR")
  end

  it "ignores badges inside code blocks" do
    write_page("guide.md", <<~MD)
      ```markdown
      :badge[Status]{type="info"}
      ```
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "validates all valid types without warnings" do
    write_page("guide.md", <<~MD)
      :badge[Default]{type="default"}
      :badge[Success]{type="success"}
      :badge[Warning]{type="warning"}
      :badge[Danger]{type="danger"}
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end
end
