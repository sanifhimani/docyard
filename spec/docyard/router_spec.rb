# frozen_string_literal: true

RSpec.describe Docyard::Router do
  include_context "with docs directory"

  let(:router) { described_class.new(docs_path: docs_dir) }

  describe "#resolve" do
    context "when mapping root path" do
      it "maps / to docs/index.md", :aggregate_failures do
        create_doc("index.md")

        result = router.resolve("/")

        expect(result).to be_found
        expect(result.file_path).to eq(File.join(docs_dir, "index.md"))
      end
    end

    context "when mapping page paths" do
      it "maps /getting-started to docs/getting-started.md", :aggregate_failures do
        create_doc("getting-started.md")

        result = router.resolve("/getting-started")

        expect(result).to be_found
        expect(result.file_path).to eq(File.join(docs_dir, "getting-started.md"))
      end

      it "maps /getting-started/ to docs/getting-started.md (strips trailing slash)", :aggregate_failures do
        create_doc("getting-started.md")

        result = router.resolve("/getting-started/")

        expect(result).to be_found
        expect(result.file_path).to eq(File.join(docs_dir, "getting-started.md"))
      end

      it "maps /getting-started.md to docs/getting-started.md (strips .md)", :aggregate_failures do
        create_doc("getting-started.md")

        result = router.resolve("/getting-started.md")

        expect(result).to be_found
        expect(result.file_path).to eq(File.join(docs_dir, "getting-started.md"))
      end
    end

    context "when mapping nested paths" do
      it "maps /guide/setup to docs/guide/setup.md", :aggregate_failures do
        create_doc("guide/setup.md")

        result = router.resolve("/guide/setup")

        expect(result).to be_found
        expect(result.file_path).to eq(File.join(docs_dir, "guide/setup.md"))
      end

      it "maps /guide/setup/ to docs/guide/setup.md (strips trailing slash)", :aggregate_failures do
        create_doc("guide/setup.md")

        result = router.resolve("/guide/setup/")

        expect(result).to be_found
        expect(result.file_path).to eq(File.join(docs_dir, "guide/setup.md"))
      end
    end

    context "when trying directory index" do
      it "maps /guide to docs/guide/index.md", :aggregate_failures do
        create_doc("guide/index.md")

        result = router.resolve("/guide")

        expect(result).to be_found
        expect(result.file_path).to eq(File.join(docs_dir, "guide/index.md"))
      end

      it "prefers file over directory index" do
        create_doc("guide.md", "---\ntitle: Guide File\n---")
        create_doc("guide/index.md", "---\ntitle: Guide Index\n---")

        result = router.resolve("/guide")

        expect(result.file_path).to eq(File.join(docs_dir, "guide.md"))
      end
    end

    context "when file does not exist" do
      it "returns not_found result", :aggregate_failures do
        result = router.resolve("/nonexistent")

        expect(result).to be_not_found
        expect(result.file_path).to be_nil
      end
    end
  end
end
