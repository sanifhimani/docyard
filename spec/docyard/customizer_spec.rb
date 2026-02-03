# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe Docyard::Customizer do
  around do |example|
    temp_dir = Dir.mktmpdir
    original_dir = Dir.pwd
    Dir.chdir(temp_dir)
    setup_project_structure
    example.run
  ensure
    Dir.chdir(original_dir)
    FileUtils.rm_rf(temp_dir)
  end

  before do
    allow($stdout).to receive(:puts)
  end

  def setup_project_structure
    FileUtils.mkdir_p("docs")
    File.write("docyard.yml", <<~YAML)
      title: "Test Docs"
      source: "docs"
    YAML
  end

  describe "#run" do
    context "with default options" do
      let(:customizer) { described_class.new }

      it "creates _custom directory" do
        customizer.generate
        expect(File.directory?("docs/_custom")).to be true
      end

      it "creates styles.css file" do
        customizer.generate
        expect(File.exist?("docs/_custom/styles.css")).to be true
      end

      it "creates scripts.js file" do
        customizer.generate
        expect(File.exist?("docs/_custom/scripts.js")).to be true
      end

      it "completes without error" do
        expect { customizer.generate }.not_to raise_error
      end

      it "styles.css contains CSS variables", :aggregate_failures do
        customizer.generate
        content = File.read("docs/_custom/styles.css")
        expect(content).to include("--primary:")
        expect(content).to include("--background:")
      end

      it "styles.css includes header comment" do
        customizer.generate
        content = File.read("docs/_custom/styles.css")
        expect(content).to include("DOCYARD THEME CUSTOMIZATION")
      end

      it "styles.css includes category headers", :aggregate_failures do
        customizer.generate
        content = File.read("docs/_custom/styles.css")
        expect(content).to include("/* Colors */")
        expect(content).to include("/* Typography */")
      end

      it "styles.css includes both light and dark mode sections", :aggregate_failures do
        customizer.generate
        content = File.read("docs/_custom/styles.css")
        expect(content).to include(":root {")
        expect(content).to include(".dark {")
      end

      it "scripts.js contains DOMContentLoaded listener" do
        customizer.generate
        content = File.read("docs/_custom/scripts.js")
        expect(content).to include("DOMContentLoaded")
      end

      it "scripts.js includes header comment" do
        customizer.generate
        content = File.read("docs/_custom/scripts.js")
        expect(content).to include("DOCYARD CUSTOM SCRIPTS")
      end
    end

    context "with minimal option" do
      let(:customizer) { described_class.new(minimal: true) }

      it "creates styles.css without header comments", :aggregate_failures do
        customizer.generate
        content = File.read("docs/_custom/styles.css")
        expect(content).not_to include("DOCYARD THEME CUSTOMIZATION")
        expect(content).not_to include("Generated with:")
      end

      it "creates styles.css without category headers", :aggregate_failures do
        customizer.generate
        content = File.read("docs/_custom/styles.css")
        expect(content).not_to include("/* Colors */")
        expect(content).not_to include("/* Typography */")
      end

      it "creates scripts.js without header comments", :aggregate_failures do
        customizer.generate
        content = File.read("docs/_custom/scripts.js")
        expect(content).not_to include("DOCYARD CUSTOM SCRIPTS")
        expect(content).not_to include("Generated with:")
      end

      it "still includes CSS variables" do
        customizer.generate
        content = File.read("docs/_custom/styles.css")
        expect(content).to include("--primary:")
      end
    end

    context "when files already exist" do
      let(:customizer) { described_class.new }

      before do
        FileUtils.mkdir_p("docs/_custom")
        File.write("docs/_custom/styles.css", "/* existing */")
        File.write("docs/_custom/scripts.js", "// existing")
      end

      it "overwrites existing styles.css", :aggregate_failures do
        customizer.generate
        content = File.read("docs/_custom/styles.css")
        expect(content).not_to include("/* existing */")
        expect(content).to include("--primary:")
      end

      it "overwrites existing scripts.js", :aggregate_failures do
        customizer.generate
        content = File.read("docs/_custom/scripts.js")
        expect(content).not_to include("// existing")
        expect(content).to include("DOMContentLoaded")
      end
    end

    context "when source directory does not exist" do
      before do
        FileUtils.rm_rf("docs")
      end

      it "raises ConfigError" do
        customizer = described_class.new
        expect { customizer.generate }.to raise_error(Docyard::ConfigError, /does not exist/)
      end
    end
  end

  describe "variable parsing" do
    let(:customizer) { described_class.new }

    it "extracts all CSS custom properties from variables.css", :aggregate_failures do
      customizer.generate
      content = File.read("docs/_custom/styles.css")

      expect(content).to include("--foreground:")
      expect(content).to include("--sidebar:")
      expect(content).to include("--font-sans:")
      expect(content).to include("--spacing-1:")
    end

    it "preserves variable values" do
      customizer.generate
      content = File.read("docs/_custom/styles.css")

      expect(content).to include("oklch")
    end
  end

  describe "variable grouping" do
    let(:customizer) { described_class.new }

    it "groups sidebar variables together", :aggregate_failures do
      customizer.generate
      content = File.read("docs/_custom/styles.css")

      sidebar_section = content[%r{/\* Sidebar \*/.*?(?=/\* \w+ \*/|\n\n\})}m]
      expect(sidebar_section).to include("--sidebar:")
      expect(sidebar_section).to include("--sidebar-foreground:")
    end

    it "groups typography variables together" do
      customizer.generate
      content = File.read("docs/_custom/styles.css")

      expect(content).to match(%r{/\* Typography \*/.*?--font-}m)
    end

    it "groups spacing variables together" do
      customizer.generate
      content = File.read("docs/_custom/styles.css")

      expect(content).to match(%r{/\* Spacing \*/.*?--spacing-}m)
    end
  end
end
