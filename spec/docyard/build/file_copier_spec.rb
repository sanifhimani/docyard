# frozen_string_literal: true

RSpec.describe Docyard::Build::FileCopier do
  let(:temp_dir) { Dir.mktmpdir }
  let(:docs_dir) { File.join(temp_dir, "docs") }
  let(:output_dir) { File.join(temp_dir, "dist") }
  let(:config) do
    Docyard::Config.load(temp_dir).tap do |c|
      c.data["build"]["output_dir"] = output_dir
    end
  end

  before do
    FileUtils.mkdir_p(docs_dir)
    FileUtils.mkdir_p(output_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#copy" do
    context "with user assets" do
      before do
        Dir.chdir(temp_dir) do
          assets_dir = File.join(docs_dir, "assets")
          FileUtils.mkdir_p(File.join(assets_dir, "images"))
          File.write(File.join(assets_dir, "style.css"), "body { color: red; }")
          File.write(File.join(assets_dir, "images", "logo.png"), "fake png data")
        end
      end

      it "copies user assets to output directory", :aggregate_failures do
        Dir.chdir(temp_dir) do
          copier = described_class.new(config, verbose: false)
          copier.copy

          expect(File.exist?(File.join(output_dir, "assets", "style.css"))).to be true
          expect(File.exist?(File.join(output_dir, "assets", "images", "logo.png"))).to be true
        end
      end

      it "preserves directory structure" do
        Dir.chdir(temp_dir) do
          copier = described_class.new(config, verbose: false)
          copier.copy

          expect(Dir.exist?(File.join(output_dir, "assets", "images"))).to be true
        end
      end

      it "returns the number of files copied" do
        Dir.chdir(temp_dir) do
          copier = described_class.new(config, verbose: false)
          count = copier.copy

          expect(count).to be >= 2
        end
      end
    end

    context "with no user assets" do
      it "returns 0 when no assets directory exists" do
        Dir.chdir(temp_dir) do
          copier = described_class.new(config, verbose: false)
          count = copier.copy

          expect(count).to be >= 0
        end
      end
    end

    context "with default branding assets" do
      it "copies default logo and favicon", :aggregate_failures do
        Dir.chdir(temp_dir) do
          copier = described_class.new(config, verbose: false)
          copier.copy

          expect(File.exist?(File.join(output_dir, "assets", "logo.svg"))).to be true
          expect(File.exist?(File.join(output_dir, "assets", "logo-dark.svg"))).to be true
          expect(File.exist?(File.join(output_dir, "assets", "favicon.svg"))).to be true
        end
      end
    end

    context "with user branding assets" do
      before do
        Dir.chdir(temp_dir) do
          File.write(File.join(docs_dir, "my-logo.png"), "custom logo")
          config.data["branding"] = { "logo" => "my-logo.png" }
        end
      end

      it "copies user-provided branding assets" do
        Dir.chdir(temp_dir) do
          copier = described_class.new(config, verbose: false)
          copier.copy

          expect(File.exist?(File.join(output_dir, "assets", "my-logo.png"))).to be true
        end
      end
    end

    context "with verbose mode" do
      before do
        Dir.chdir(temp_dir) do
          assets_dir = File.join(docs_dir, "assets")
          FileUtils.mkdir_p(assets_dir)
          File.write(File.join(assets_dir, "test.css"), "test")
        end
      end

      it "outputs copy progress" do
        Dir.chdir(temp_dir) do
          copier = described_class.new(config, verbose: true)

          expect { copier.copy }.to output(/Copied/).to_stdout
        end
      end
    end
  end
end
