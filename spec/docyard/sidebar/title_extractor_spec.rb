# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Docyard::Sidebar::TitleExtractor do
  let(:extractor) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  def create_file(path, content)
    full_path = File.join(temp_dir, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  describe "#extract" do
    context "with frontmatter title" do
      it "extracts title from frontmatter" do
        file = create_file("test.md", "---\ntitle: My Title\n---\n\n# Content")

        expect(extractor.extract(file)).to eq("My Title")
      end
    end

    context "without frontmatter" do
      it "derives title from filename" do
        file = create_file("getting-started.md", "# Content")

        expect(extractor.extract(file)).to eq("Getting Started")
      end
    end

    context "with index file" do
      it "returns Home" do
        file = create_file("index.md", "# Content")

        expect(extractor.extract(file)).to eq("Home")
      end
    end

    context "with hyphens and underscores" do
      it "converts to spaces and capitalizes" do
        file = create_file("api-reference_guide.md", "# Content")

        expect(extractor.extract(file)).to eq("Api Reference Guide")
      end
    end

    context "with non-existent file" do
      it "derives from filename" do
        result = extractor.extract("/nonexistent/test-file.md")

        expect(result).to eq("Test File")
      end
    end

    context "with unreadable file" do
      it "falls back to filename" do
        file = create_file("test.md", "content")
        FileUtils.chmod(0o000, file)

        result = extractor.extract(file)

        expect(result).to eq("Test")
      ensure
        FileUtils.chmod(0o644, file)
      end
    end

    context "with invalid frontmatter" do
      it "falls back to filename" do
        file = create_file("test.md", "---\ninvalid yaml: : :\n---\n")

        result = extractor.extract(file)

        expect(result).to eq("Test")
      end
    end
  end
end
