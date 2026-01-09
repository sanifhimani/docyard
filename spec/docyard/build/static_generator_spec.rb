# frozen_string_literal: true

RSpec.describe Docyard::Build::StaticGenerator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:docs_dir) { File.join(temp_dir, "docs") }
  let(:output_dir) { File.join(temp_dir, "dist") }
  let(:config) do
    Docyard::Config.load(temp_dir).tap do |c|
      c.data["build"]["output"] = output_dir
    end
  end

  before do
    FileUtils.mkdir_p(docs_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#generate" do
    context "with simple markdown files" do
      before do
        File.write(File.join(docs_dir, "index.md"), "# Home\n\nWelcome to the docs!")
        File.write(File.join(docs_dir, "guide.md"), "# Guide\n\nHow to use it")
      end

      it "generates HTML files for all markdown files", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          count = generator.generate

          expect(count).to eq(2)
          expect(File.exist?(File.join(output_dir, "index.html"))).to be true
          expect(File.exist?(File.join(output_dir, "guide", "index.html"))).to be true
        end
      end

      it "generates pretty URLs", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          guide_html = File.read(File.join(output_dir, "guide", "index.html"))

          expect(guide_html).to include("<h1")
          expect(guide_html).to include("Guide")
        end
      end

      it "includes sidebar in generated HTML" do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          index_html = File.read(File.join(output_dir, "index.html"))

          expect(index_html).to include("sidebar")
        end
      end
    end

    context "with nested directory structure" do
      before do
        FileUtils.mkdir_p(File.join(docs_dir, "getting-started"))
        File.write(File.join(docs_dir, "index.md"), "# Home")
        File.write(File.join(docs_dir, "getting-started", "intro.md"), "# Intro")
        File.write(File.join(docs_dir, "getting-started", "index.md"), "# Getting Started")
      end

      it "preserves directory structure with pretty URLs", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          expect(File.exist?(File.join(output_dir, "index.html"))).to be true
          expect(File.exist?(File.join(output_dir, "getting-started", "index.html"))).to be true
          expect(File.exist?(File.join(output_dir, "getting-started", "intro", "index.html"))).to be true
        end
      end
    end

    context "with base configuration" do
      before do
        config.data["build"]["base"] = "/my-docs/"
        File.write(File.join(docs_dir, "index.md"), "# Home")
      end

      it "uses base in generated HTML", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          index_html = File.read(File.join(output_dir, "index.html"))

          expect(index_html).to include('href="/my-docs/')
          expect(index_html).to include('href="/my-docs/_docyard/favicon.svg"')
        end
      end
    end

    context "with verbose mode" do
      before do
        File.write(File.join(docs_dir, "index.md"), "# Home")
      end

      it "outputs generation progress" do
        Dir.chdir(temp_dir) do
          progress_bar = instance_double(TTY::ProgressBar)
          allow(progress_bar).to receive(:advance)
          allow(TTY::ProgressBar).to receive(:new).and_return(progress_bar)

          generator = described_class.new(config, verbose: true)

          expect { generator.generate }.to output(/Generated:/).to_stdout
        end
      end
    end

    context "with custom HTML landing page" do
      before do
        File.write(File.join(docs_dir, "index.html"), "<html><body>Custom Landing</body></html>")
        File.write(File.join(docs_dir, "index.md"), "# Home")
        File.write(File.join(docs_dir, "guide.md"), "# Guide")
      end

      it "copies index.html directly to output", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          output_html = File.read(File.join(output_dir, "index.html"))
          expect(output_html).to eq("<html><body>Custom Landing</body></html>")
        end
      end

      it "skips index.md when index.html exists", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          count = generator.generate

          expect(count).to eq(1)
          expect(File.exist?(File.join(output_dir, "guide", "index.html"))).to be true
        end
      end

      it "still processes other markdown files", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          guide_html = File.read(File.join(output_dir, "guide", "index.html"))
          expect(guide_html).to include("<h1")
          expect(guide_html).to include("Guide")
        end
      end
    end

    context "with search exclude patterns" do
      before do
        FileUtils.mkdir_p(File.join(docs_dir, "drafts"))
        File.write(File.join(docs_dir, "index.md"), "# Home")
        File.write(File.join(docs_dir, "guide.md"), "# Guide")
        File.write(File.join(docs_dir, "drafts", "wip.md"), "# Work in Progress")
        config.data["search"]["exclude"] = ["/drafts/*"]
      end

      it "marks excluded pages with data-pagefind-ignore", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          draft_html = File.read(File.join(output_dir, "drafts", "wip", "index.html"))
          guide_html = File.read(File.join(output_dir, "guide", "index.html"))

          expect(draft_html).to include("data-pagefind-ignore")
          expect(draft_html).not_to include("data-pagefind-body")
          expect(guide_html).to include("data-pagefind-body")
        end
      end
    end
  end
end
