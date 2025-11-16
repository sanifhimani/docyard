# frozen_string_literal: true

RSpec.describe Docyard::Builder do
  let(:temp_dir) { Dir.mktmpdir }
  let(:docs_dir) { File.join(temp_dir, "docs") }
  let(:output_dir) { File.join(temp_dir, "dist") }

  before do
    Dir.chdir(temp_dir) do
      FileUtils.mkdir_p(docs_dir)
      File.write(File.join(docs_dir, "index.md"), "# Home\n\nWelcome!")
      File.write(File.join(docs_dir, "guide.md"), "# Guide\n\nContent")

      File.write("docyard.yml", <<~YAML)
        site:
          title: "Test Docs"
        build:
          output_dir: "dist"
          base_url: "/"
      YAML
    end
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#build" do
    context "with default options" do
      it "successfully builds the site", :aggregate_failures do
        Dir.chdir(temp_dir) do
          builder = described_class.new(clean: true, verbose: false)
          result = builder.build

          expect(result).to be true
          expect(Dir.exist?(output_dir)).to be true
          expect(File.exist?(File.join(output_dir, "index.html"))).to be true
          expect(File.exist?(File.join(output_dir, "guide", "index.html"))).to be true
          expect(File.exist?(File.join(output_dir, "sitemap.xml"))).to be true
          expect(File.exist?(File.join(output_dir, "robots.txt"))).to be true
        end
      end

      it "cleans output directory when clean is true" do
        Dir.chdir(temp_dir) do
          FileUtils.mkdir_p(output_dir)
          old_file = File.join(output_dir, "old-file.txt")
          File.write(old_file, "old content")

          builder = described_class.new(clean: true, verbose: false)
          builder.build

          expect(File.exist?(old_file)).to be false
        end
      end

      it "preserves existing files when clean is false" do
        Dir.chdir(temp_dir) do
          FileUtils.mkdir_p(output_dir)
          old_file = File.join(output_dir, "old-file.txt")
          File.write(old_file, "old content")

          builder = described_class.new(clean: false, verbose: false)
          builder.build

          expect(File.exist?(old_file)).to be true
        end
      end
    end

    context "with verbose option" do
      it "outputs verbose information" do
        Dir.chdir(temp_dir) do
          builder = described_class.new(clean: true, verbose: true)

          expect { builder.build }.to output(/Generated:/).to_stdout
        end
      end
    end

    describe "robots.txt generation" do
      it "generates robots.txt with correct content", :aggregate_failures do
        Dir.chdir(temp_dir) do
          builder = described_class.new(clean: true, verbose: false)
          builder.build

          robots_content = File.read(File.join(output_dir, "robots.txt"))

          expect(robots_content).to include("User-agent: *")
          expect(robots_content).to include("Allow: /")
          expect(robots_content).to include("Sitemap: /sitemap.xml")
        end
      end

      it "uses base_url in sitemap reference" do
        Dir.chdir(temp_dir) do
          File.write("docyard.yml", <<~YAML)
            build:
              output_dir: "dist"
              base_url: "/my-docs/"
          YAML

          builder = described_class.new(clean: true, verbose: false)
          builder.build

          robots_content = File.read(File.join(output_dir, "robots.txt"))

          expect(robots_content).to include("Sitemap: /my-docs/sitemap.xml")
        end
      end
    end
  end
end
