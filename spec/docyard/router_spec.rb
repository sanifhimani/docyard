# frozen_string_literal: true

RSpec.describe Docyard::Router do
  let(:docs_path) { "docs" }
  let(:router) { described_class.new(docs_path: docs_path) }

  describe "#resolve" do
    before do
      allow(File).to receive(:file?).and_return(false)
    end

    context "when mapping root path" do
      it "maps / to docs/index.md" do
        allow(File).to receive(:file?).with("docs/index.md").and_return(true)

        expect(router.resolve("/")).to eq("docs/index.md")
      end
    end

    context "when mapping page paths" do
      it "maps /getting-started to docs/getting-started.md" do
        allow(File).to receive(:file?).with("docs/getting-started.md").and_return(true)

        expect(router.resolve("/getting-started")).to eq("docs/getting-started.md")
      end

      it "maps /getting-started.md to docs/getting-started.md (strips .md extension)" do
        allow(File).to receive(:file?).with("docs/getting-started.md").and_return(true)

        expect(router.resolve("/getting-started.md")).to eq("docs/getting-started.md")
      end
    end

    context "when mapping nested paths" do
      it "maps /guide/setup to docs/guide/setup.md" do
        allow(File).to receive(:file?).with("docs/guide/setup.md").and_return(true)

        expect(router.resolve("/guide/setup")).to eq("docs/guide/setup.md")
      end
    end

    context "when trying directory index" do
      it "maps /guide to docs/guide/index.md" do
        allow(File).to receive(:file?).with("docs/guide.md").and_return(false)
        allow(File).to receive(:file?).with("docs/guide/index.md").and_return(true)

        expect(router.resolve("/guide")).to eq("docs/guide/index.md")
      end
    end

    context "when file does not exist" do
      it "returns nil" do
        expect(router.resolve("/nonexistent")).to be_nil
      end
    end
  end
end
