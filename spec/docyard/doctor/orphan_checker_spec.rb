# frozen_string_literal: true

RSpec.describe Docyard::Doctor::OrphanChecker do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config) { instance_double(Docyard::Config, sidebar: "config") }
  let(:checker) { described_class.new(temp_dir, config) }

  after { FileUtils.remove_entry(temp_dir) }

  describe "#check" do
    it "returns empty array for auto sidebar mode" do
      allow(config).to receive(:sidebar).and_return("auto")
      File.write(File.join(temp_dir, "orphan.md"), "# Orphan")

      expect(checker.check).to eq([])
    end

    it "returns empty array when no sidebar config exists" do
      File.write(File.join(temp_dir, "page.md"), "# Page")

      expect(checker.check).to eq([])
    end

    it "detects orphan pages not in sidebar", :aggregate_failures do
      File.write(File.join(temp_dir, "_sidebar.yml"), "- listed")
      File.write(File.join(temp_dir, "listed.md"), "# Listed")
      File.write(File.join(temp_dir, "orphan.md"), "# Orphan")

      orphans = checker.check

      expect(orphans.size).to eq(1)
      expect(orphans.first.file).to eq("orphan.md")
    end

    it "excludes files starting with underscore" do
      File.write(File.join(temp_dir, "_sidebar.yml"), "- page")
      File.write(File.join(temp_dir, "page.md"), "# Page")
      File.write(File.join(temp_dir, "_shared.md"), "# Shared")

      expect(checker.check).to eq([])
    end

    it "excludes root index.md as it is the landing page" do
      File.write(File.join(temp_dir, "_sidebar.yml"), "- page")
      File.write(File.join(temp_dir, "page.md"), "# Page")
      File.write(File.join(temp_dir, "index.md"), "# Landing")

      expect(checker.check).to eq([])
    end

    it "handles nested sidebar items", :aggregate_failures do
      sidebar_config = <<~YAML
        - guide:
            items:
              - intro
              - advanced
      YAML
      File.write(File.join(temp_dir, "_sidebar.yml"), sidebar_config)
      FileUtils.mkdir_p(File.join(temp_dir, "guide"))
      File.write(File.join(temp_dir, "guide", "intro.md"), "# Intro")
      File.write(File.join(temp_dir, "guide", "advanced.md"), "# Advanced")
      File.write(File.join(temp_dir, "orphan.md"), "# Orphan")

      orphans = checker.check

      expect(orphans.size).to eq(1)
      expect(orphans.first.file).to eq("orphan.md")
    end
  end
end
