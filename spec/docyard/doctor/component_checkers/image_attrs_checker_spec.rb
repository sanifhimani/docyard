# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::ImageAttrsChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid image attributes" do
    content = <<~MD
      ![Alt text](/image.png){caption="A caption"}
      ![Alt text](/image.png){width="300" height="200"}
      ![Alt text](/image.png){nozoom}
    MD

    expect(check(content)).to be_empty
  end

  it "detects unknown attribute", :aggregate_failures do
    diagnostics = check('![Alt](/image.png){size="300"}')

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("IMAGE_UNKNOWN_ATTR")
    expect(diagnostics.first.message).to include("unknown image attribute 'size'")
  end

  it "suggests valid attribute when typo detected" do
    diagnostics = check('![Alt](/image.png){capton="text"}')

    expect(diagnostics.first.message).to include("did you mean 'caption'?")
  end

  it "detects multiple unknown attributes", :aggregate_failures do
    diagnostics = check('![Alt](/image.png){size="300" border="1"}')

    expect(diagnostics.size).to eq(2)
  end

  it "ignores images inside code blocks" do
    content = <<~MD
      ```markdown
      ![Alt](/image.png){invalid="attr"}
      ```
    MD

    expect(check(content)).to be_empty
  end

  it "ignores regular images without attributes" do
    expect(check("![Alt text](/image.png)")).to be_empty
  end
end
