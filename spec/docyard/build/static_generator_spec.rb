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
        config.data["sidebar"] = "auto"
        File.write(File.join(docs_dir, "index.md"), "---\ntitle: Home\n---\n# Home\n\nWelcome to the docs!")
        File.write(File.join(docs_dir, "intro.md"), "---\ntitle: Introduction\n---\n# Intro")
        File.write(File.join(docs_dir, "guide.md"), "---\ntitle: Guide\n---\n# Guide\n\nHow to use it")
      end

      it "generates HTML files for all markdown files", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          count = generator.generate

          expect(count).to eq(3)
          expect(File.exist?(File.join(output_dir, "index.html"))).to be true
          expect(File.exist?(File.join(output_dir, "intro", "index.html"))).to be true
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

      it "includes sidebar with navigation links", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          guide_html = File.read(File.join(output_dir, "guide", "index.html"))

          expect(guide_html).to include("sidebar")
          expect(guide_html).to include('href="/guide"')
          expect(guide_html).to include('href="/intro"')
        end
      end

      it "includes prev/next navigation", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          intro_html = File.read(File.join(output_dir, "intro", "index.html"))

          expect(intro_html).to include("pager")
          expect(intro_html).to include("Previous")
          expect(intro_html).to include('href="/guide"')
        end
      end
    end

    context "with nested directory structure" do
      before do
        config.data["sidebar"] = "auto"
        FileUtils.mkdir_p(File.join(docs_dir, "getting-started"))
        File.write(File.join(docs_dir, "index.md"), "---\ntitle: Home\n---\n# Home")
        File.write(File.join(docs_dir, "getting-started", "intro.md"), "---\ntitle: Intro\n---\n# Intro")
        File.write(File.join(docs_dir, "getting-started", "index.md"),
                   "---\ntitle: Getting Started\n---\n# Getting Started")
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

      it "includes sidebar with section navigation", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          intro_html = File.read(File.join(output_dir, "getting-started", "intro", "index.html"))

          expect(intro_html).to include("Getting Started")
          expect(intro_html).to include('href="/getting-started"')
          expect(intro_html).to include('href="/getting-started/intro"')
        end
      end

      it "includes prev/next navigation within sections", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          intro_html = File.read(File.join(output_dir, "getting-started", "intro", "index.html"))

          expect(intro_html).to include("pager")
          expect(intro_html).to include("Previous")
          expect(intro_html).to include('href="/getting-started"')
        end
      end

      it "marks current page as active in sidebar" do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          intro_html = File.read(File.join(output_dir, "getting-started", "intro", "index.html"))

          expect(intro_html).to match(%r{href="/getting-started/intro"[^>]*class="[^"]*active})
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

          output = capture_logger_output { generator.generate }

          expect(output).to match(/Generated:/)
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

    context "with headings for TOC" do
      before do
        File.write(File.join(docs_dir, "index.md"),
                   "---\ntitle: Home\n---\n# Main Title\n\n## Section One\n\nContent here.\n\n" \
                   "## Section Two\n\nMore content.\n\n### Subsection\n\nDetails.\n")
      end

      it "adds anchor links to headings", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          index_html = File.read(File.join(output_dir, "index.html"))

          expect(index_html).to include('id="section-one"')
          expect(index_html).to include('id="section-two"')
          expect(index_html).to include("heading-anchor")
        end
      end

      it "generates table of contents", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          index_html = File.read(File.join(output_dir, "index.html"))

          expect(index_html).to include("toc")
          expect(index_html).to include('href="#section-one"')
          expect(index_html).to include('href="#section-two"')
        end
      end
    end

    context "with branding configuration" do
      before do
        File.write(File.join(docs_dir, "index.md"), "# Home")
        config.data["title"] = "My Custom Docs"
      end

      it "includes site title in generated HTML" do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          index_html = File.read(File.join(output_dir, "index.html"))

          expect(index_html).to include("My Custom Docs")
        end
      end

      it "includes default logo path" do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          index_html = File.read(File.join(output_dir, "index.html"))

          expect(index_html).to include("logo")
        end
      end
    end

    context "with tab navigation configured" do
      before do
        config.data["tabs"] = [
          { "text" => "Guide", "href" => "/guide" },
          { "text" => "API", "href" => "/api" }
        ]
        FileUtils.mkdir_p(File.join(docs_dir, "guide"))
        FileUtils.mkdir_p(File.join(docs_dir, "api"))
        File.write(File.join(docs_dir, "guide", "index.md"), "---\ntitle: Guide\n---\n# Guide")
        File.write(File.join(docs_dir, "guide", "setup.md"), "---\ntitle: Setup\n---\n# Setup")
        File.write(File.join(docs_dir, "api", "index.md"), "---\ntitle: API\n---\n# API")

        File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
          - guide:
              items:
                - index: { text: Guide }
                - setup: { text: Setup }
          - api:
              items:
                - index: { text: API }
        YAML
      end

      it "renders tab navigation in generated HTML" do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          guide_html = File.read(File.join(output_dir, "guide", "index.html"))

          expect(guide_html).to include("tab-bar")
        end
      end

      it "marks the correct tab as active based on current path", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          guide_html = File.read(File.join(output_dir, "guide", "setup", "index.html"))

          expect(guide_html).to match(%r{href="/guide"[^>]*class="[^"]*is-active})
          expect(guide_html).not_to match(%r{href="/api"[^>]*class="[^"]*is-active})
        end
      end

      it "scopes sidebar to current tab section", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          guide_html = File.read(File.join(output_dir, "guide", "setup", "index.html"))

          expect(guide_html).to include('href="/guide/setup"')
          sidebar_section = guide_html[%r{class="sidebar".*?</nav>}m]
          expect(sidebar_section).not_to include('href="/api"')
        end
      end
    end

    context "with error page generation" do
      before do
        File.write(File.join(docs_dir, "index.md"), "# Home")
      end

      it "generates default 404.html when no custom page exists", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          expect(File.exist?(File.join(output_dir, "404.html"))).to be true

          error_html = File.read(File.join(output_dir, "404.html"))
          expect(error_html).to include("404")
          expect(error_html).to include("Page not found")
          expect(error_html).to include("Back to home")
        end
      end

      it "uses custom 404.html when provided", :aggregate_failures do
        File.write(File.join(docs_dir, "404.html"), "<html><body>Custom 404 Page</body></html>")

        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          error_html = File.read(File.join(output_dir, "404.html"))
          expect(error_html).to eq("<html><body>Custom 404 Page</body></html>")
        end
      end
    end

    context "with markdown content features" do
      before do
        File.write(File.join(docs_dir, "index.md"),
                   "---\ntitle: Features\n---\n# Features\n\n" \
                   "**Bold text** and *italic text* and `inline code`.\n\n" \
                   "```ruby\ndef hello\n  puts \"world\"\nend\n```\n\n" \
                   "| Column 1 | Column 2 |\n|----------|----------|\n| Data 1   | Data 2   |\n")
      end

      it "renders markdown formatting correctly", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          index_html = File.read(File.join(output_dir, "index.html"))

          expect(index_html).to include("<strong>Bold text</strong>")
          expect(index_html).to include("<em>italic text</em>")
          expect(index_html).to include("inline code</code>")
        end
      end

      it "renders code blocks with syntax highlighting", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          index_html = File.read(File.join(output_dir, "index.html"))

          expect(index_html).to include("highlight")
          expect(index_html).to include("def")
        end
      end

      it "wraps tables for responsive display", :aggregate_failures do
        Dir.chdir(temp_dir) do
          generator = described_class.new(config, verbose: false)
          generator.generate

          index_html = File.read(File.join(output_dir, "index.html"))

          expect(index_html).to include("table-wrapper")
          expect(index_html).to include("<table")
        end
      end
    end
  end
end
