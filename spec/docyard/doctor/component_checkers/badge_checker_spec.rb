# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::BadgeChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid badges" do
    content = <<~MD
      :badge[New]
      :badge[Beta]{type="warning"}
      :badge[Stable]{type="success"}
    MD

    expect(check(content)).to be_empty
  end

  it "detects unknown badge type", :aggregate_failures do
    diagnostics = check(':badge[Status]{type="info"}')

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("BADGE_UNKNOWN_TYPE")
    expect(diagnostics.first.message).to include("unknown badge type 'info'")
  end

  it "detects unknown badge attribute", :aggregate_failures do
    diagnostics = check(':badge[Status]{color="red"}')

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("BADGE_UNKNOWN_ATTR")
    expect(diagnostics.first.message).to include("unknown badge attribute 'color'")
  end

  it "suggests valid type when typo detected" do
    diagnostics = check(':badge[Status]{type="sucess"}')

    expect(diagnostics.first.message).to include("did you mean 'success'?")
  end

  it "detects multiple issues on same line", :aggregate_failures do
    diagnostics = check(':badge[A]{type="info"} :badge[B]{color="blue"}')

    expect(diagnostics.size).to eq(2)
    expect(diagnostics.map(&:code)).to contain_exactly("BADGE_UNKNOWN_TYPE", "BADGE_UNKNOWN_ATTR")
  end

  it "ignores badges inside code blocks" do
    content = <<~MD
      ```markdown
      :badge[Status]{type="info"}
      ```
    MD

    expect(check(content)).to be_empty
  end

  it "validates all valid types without warnings" do
    content = <<~MD
      :badge[Default]{type="default"}
      :badge[Success]{type="success"}
      :badge[Warning]{type="warning"}
      :badge[Danger]{type="danger"}
    MD

    expect(check(content)).to be_empty
  end
end
