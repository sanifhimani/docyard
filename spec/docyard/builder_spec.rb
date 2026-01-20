# frozen_string_literal: true

RSpec.describe Docyard::Builder do
  include_context "with docs directory"

  let(:output_dir) { File.join(temp_dir, "dist") }

  before do
    create_doc("index.md", "# Home\n\nWelcome!")
    create_doc("guide.md", "# Guide\n\nContent")
    create_config(<<~YAML)
      title: "Test Docs"
      build:
        output: "dist"
        base: "/"
    YAML
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

          described_class.new(clean: true, verbose: false).build

          expect(File.exist?(old_file)).to be false
        end
      end

      it "preserves existing files when clean is false" do
        Dir.chdir(temp_dir) do
          FileUtils.mkdir_p(output_dir)
          old_file = File.join(output_dir, "old-file.txt")
          File.write(old_file, "old content")

          described_class.new(clean: false, verbose: false).build

          expect(File.exist?(old_file)).to be true
        end
      end
    end

    context "with verbose option" do
      it "outputs verbose information" do
        Dir.chdir(temp_dir) do
          builder = described_class.new(clean: true, verbose: true)

          output = capture_logger_output { builder.build }

          expect(output).to match(/Generated:/)
        end
      end
    end

    describe "robots.txt generation" do
      it "generates robots.txt with correct content", :aggregate_failures do
        Dir.chdir(temp_dir) do
          described_class.new(clean: true, verbose: false).build

          robots_content = File.read(File.join(output_dir, "robots.txt"))

          expect(robots_content).to include("User-agent: *")
          expect(robots_content).to include("Allow: /")
          expect(robots_content).to include("Sitemap: /sitemap.xml")
        end
      end

      it "uses base in sitemap reference" do
        Dir.chdir(temp_dir) do
          create_config(<<~YAML)
            build:
              output: "dist"
              base: "/my-docs/"
          YAML

          described_class.new(clean: true, verbose: false).build

          robots_content = File.read(File.join(output_dir, "robots.txt"))

          expect(robots_content).to include("Sitemap: /my-docs/sitemap.xml")
        end
      end
    end
  end
end
