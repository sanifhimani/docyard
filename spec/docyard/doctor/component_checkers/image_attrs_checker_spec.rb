# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::ImageAttrsChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid image attributes" do
    write_page("guide.md", <<~MD)
      ![Alt text](/image.png){caption="A caption"}
      ![Alt text](/image.png){width="300" height="200"}
      ![Alt text](/image.png){nozoom}
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects unknown attribute", :aggregate_failures do
    write_page("guide.md", '![Alt](/image.png){size="300"}')

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("IMAGE_UNKNOWN_ATTR")
    expect(diagnostics.first.message).to include("unknown image attribute 'size'")
  end

  it "suggests valid attribute when typo detected" do
    write_page("guide.md", '![Alt](/image.png){capton="text"}')

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.first.message).to include("did you mean 'caption'?")
  end

  it "detects multiple unknown attributes", :aggregate_failures do
    write_page("guide.md", '![Alt](/image.png){size="300" border="1"}')

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(2)
  end

  it "ignores images inside code blocks" do
    write_page("guide.md", <<~MD)
      ```markdown
      ![Alt](/image.png){invalid="attr"}
      ```
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "ignores regular images without attributes" do
    write_page("guide.md", "![Alt text](/image.png)")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end
end
