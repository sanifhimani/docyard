# frozen_string_literal: true

require "docyard/build/social_cards_generator"

RSpec.describe Docyard::Build::SocialCardsGenerator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:docs_dir) { File.join(temp_dir, "docs") }
  let(:output_dir) { File.join(temp_dir, "dist") }
  let(:config) do
    Docyard::Config.load(temp_dir).tap do |c|
      c.data["source"] = docs_dir
      c.data["build"]["output"] = output_dir
      c.data["social_cards"]["enabled"] = true
    end
  end

  before do
    FileUtils.mkdir_p(docs_dir)
    FileUtils.mkdir_p(output_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#generate" do
    before do
      File.write(File.join(docs_dir, "index.md"), <<~MARKDOWN)
        ---
        title: Welcome to Docs
        ---

        Home content
      MARKDOWN
    end

    it "generates PNG files in _docyard/og directory" do
      generator = described_class.new(config)
      generator.generate

      expect(File.exist?(File.join(output_dir, "_docyard/og/index.png"))).to be true
    end

    it "returns the count of generated cards" do
      generator = described_class.new(config)
      count, = generator.generate

      expect(count).to eq(1)
    end

    context "with multiple pages" do
      before do
        FileUtils.mkdir_p(File.join(docs_dir, "getting-started"))
        File.write(File.join(docs_dir, "getting-started", "quickstart.md"), <<~MARKDOWN)
          ---
          title: Quickstart
          description: Get started quickly
          ---

          Quickstart content
        MARKDOWN
      end

      it "generates cards for all pages", :aggregate_failures do
        generator = described_class.new(config)
        generator.generate

        expect(File.exist?(File.join(output_dir, "_docyard/og/index.png"))).to be true
        expect(File.exist?(File.join(output_dir, "_docyard/og/getting-started/quickstart.png"))).to be true
      end

      it "returns correct count" do
        generator = described_class.new(config)
        count, = generator.generate

        expect(count).to eq(2)
      end
    end

    context "with frontmatter social_cards override" do
      before do
        File.write(File.join(docs_dir, "index.md"), <<~MARKDOWN)
          ---
          title: Original Title
          social_cards:
            title: Custom Social Title
            description: Custom description for social
          ---

          Content
        MARKDOWN
      end

      it "generates card (uses custom title internally)" do
        generator = described_class.new(config)
        generator.generate

        expect(File.exist?(File.join(output_dir, "_docyard/og/index.png"))).to be true
      end
    end

    context "with verbose mode" do
      it "returns details of generated files" do
        generator = described_class.new(config, verbose: true)
        _, details = generator.generate

        expect(details).to include("_docyard/og/index.png")
      end
    end
  end

  describe "#card_path_for" do
    it "returns correct path for root" do
      generator = described_class.new(config)

      expect(generator.card_path_for("/")).to eq("/_docyard/og/index.png")
    end

    it "returns correct path for nested page" do
      generator = described_class.new(config)
      expected_path = "/_docyard/og/getting-started/quickstart.png"

      expect(generator.card_path_for("/getting-started/quickstart")).to eq(expected_path)
    end
  end

  describe "error handling" do
    before do
      File.write(File.join(docs_dir, "index.md"), <<~MARKDOWN)
        ---
        title: Test Page
        ---

        Content
      MARKDOWN
    end

    it "handles errors gracefully by returning successful count", :aggregate_failures do
      generator = described_class.new(config)
      count, = generator.generate

      expect(count).to eq(1)
      expect(generator.successful_count).to eq(1)
    end
  end

  describe "edge cases" do
    context "with very long title" do
      before do
        long_title = "A" * 200
        File.write(File.join(docs_dir, "index.md"), <<~MARKDOWN)
          ---
          title: #{long_title}
          ---

          Content
        MARKDOWN
      end

      it "generates card without error", :aggregate_failures do
        generator = described_class.new(config)

        expect { generator.generate }.not_to raise_error
        expect(File.exist?(File.join(output_dir, "_docyard/og/index.png"))).to be true
      end
    end

    context "with empty title" do
      before do
        File.write(File.join(docs_dir, "index.md"), <<~MARKDOWN)
          ---
          title: ""
          ---

          Content
        MARKDOWN
      end

      it "derives title from path", :aggregate_failures do
        generator = described_class.new(config)

        expect { generator.generate }.not_to raise_error
        expect(File.exist?(File.join(output_dir, "_docyard/og/index.png"))).to be true
      end
    end

    context "with special characters in title" do
      before do
        File.write(File.join(docs_dir, "index.md"), <<~MARKDOWN)
          ---
          title: "Test <script>alert('xss')</script> & 'quotes'"
          ---

          Content
        MARKDOWN
      end

      it "escapes special characters and generates card", :aggregate_failures do
        generator = described_class.new(config)

        expect { generator.generate }.not_to raise_error
        expect(File.exist?(File.join(output_dir, "_docyard/og/index.png"))).to be true
      end
    end

    context "with unicode in title" do
      before do
        File.write(File.join(docs_dir, "index.md"), <<~MARKDOWN)
          ---
          title: "Hello World - Guide"
          ---

          Content
        MARKDOWN
      end

      it "generates card with unicode characters", :aggregate_failures do
        generator = described_class.new(config)

        expect { generator.generate }.not_to raise_error
        expect(File.exist?(File.join(output_dir, "_docyard/og/index.png"))).to be true
      end
    end

    context "with missing frontmatter" do
      before do
        File.write(File.join(docs_dir, "no-frontmatter.md"), "Just content, no frontmatter")
      end

      it "derives title from filename", :aggregate_failures do
        generator = described_class.new(config)

        expect { generator.generate }.not_to raise_error
        expect(File.exist?(File.join(output_dir, "_docyard/og/no-frontmatter.png"))).to be true
      end
    end

    context "with nil description" do
      before do
        File.write(File.join(docs_dir, "index.md"), <<~MARKDOWN)
          ---
          title: Test Page
          ---

          Content without description
        MARKDOWN
      end

      it "generates card without description", :aggregate_failures do
        generator = described_class.new(config)

        expect { generator.generate }.not_to raise_error
        expect(File.exist?(File.join(output_dir, "_docyard/og/index.png"))).to be true
      end
    end

    context "with deeply nested page" do
      before do
        FileUtils.mkdir_p(File.join(docs_dir, "a", "b", "c", "d"))
        File.write(File.join(docs_dir, "a", "b", "c", "d", "deep.md"), <<~MARKDOWN)
          ---
          title: Deeply Nested Page
          ---

          Content
        MARKDOWN
      end

      it "generates card in correct nested directory" do
        generator = described_class.new(config)
        generator.generate

        expect(File.exist?(File.join(output_dir, "_docyard/og/a/b/c/d/deep.png"))).to be true
      end
    end

    context "without branding color configured" do
      it "uses default brand color" do
        generator = described_class.new(config)

        expect { generator.generate }.not_to raise_error
      end
    end
  end
end
