# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe Docyard::Initializer do
  let(:temp_dir) { Dir.mktmpdir }
  let(:original_dir) { Dir.pwd }

  before do
    Dir.chdir(temp_dir)
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)
  end

  after do
    Dir.chdir(original_dir)
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    context "without project name" do
      let(:initializer) { described_class.new }

      it "sets project_path to current directory" do
        expect(initializer.project_path).to eq(".")
      end

      it "sets docs_path to docs/ in current directory" do
        expect(initializer.docs_path).to eq("./docs")
      end
    end

    context "with project name" do
      let(:initializer) { described_class.new("my-project") }

      it "sets project_path to project directory" do
        expect(initializer.project_path).to eq("./my-project")
      end

      it "sets docs_path to docs/ in project directory" do
        expect(initializer.docs_path).to eq("./my-project/docs")
      end
    end
  end

  describe "#run" do
    context "when directory is empty" do
      let(:initializer) { described_class.new }

      it "creates docs directory" do
        initializer.run
        expect(File.directory?("docs")).to be true
      end

      it "creates public directory" do
        initializer.run
        expect(File.directory?("docs/public")).to be true
      end

      it "creates docyard.yml config file" do
        initializer.run
        expect(File.exist?("docyard.yml")).to be true
      end

      it "creates _sidebar.yml" do
        initializer.run
        expect(File.exist?("docs/_sidebar.yml")).to be true
      end

      it "creates starter pages", :aggregate_failures do
        initializer.run
        expect(File.exist?("docs/index.md")).to be true
        expect(File.exist?("docs/getting-started.md")).to be true
        expect(File.exist?("docs/components.md")).to be true
      end

      it "returns true on success" do
        expect(initializer.run).to be true
      end
    end

    context "with project name" do
      let(:initializer) { described_class.new("my-docs") }

      it "creates project directory" do
        initializer.run
        expect(File.directory?("my-docs")).to be true
      end

      it "creates docs directory inside project" do
        initializer.run
        expect(File.directory?("my-docs/docs")).to be true
      end

      it "creates config file in project directory" do
        initializer.run
        expect(File.exist?("my-docs/docyard.yml")).to be true
      end

      it "replaces project name placeholder in config", :aggregate_failures do
        initializer.run
        content = File.read("my-docs/docyard.yml")
        expect(content).to include('title: "My Docs"')
        expect(content).not_to include("{{PROJECT_NAME}}")
      end

      it "replaces project name placeholder in pages", :aggregate_failures do
        initializer.run
        content = File.read("my-docs/docs/index.md")
        expect(content).to include("My Docs")
        expect(content).not_to include("{{PROJECT_NAME}}")
      end
    end

    context "when files already exist and user confirms overwrite" do
      let(:initializer) { described_class.new }

      before do
        FileUtils.mkdir_p("docs")
        allow($stdin).to receive(:gets).and_return("y\n")
      end

      it "overwrites existing files" do
        initializer.run
        expect(File.exist?("docs/index.md")).to be true
      end

      it "returns true" do
        expect(initializer.run).to be true
      end
    end

    context "when files already exist and user declines overwrite" do
      let(:initializer) { described_class.new }

      before do
        FileUtils.mkdir_p("docs")
        allow($stdin).to receive(:gets).and_return("n\n")
      end

      it "does not create new files" do
        initializer.run
        expect(File.exist?("docs/index.md")).to be false
      end

      it "returns false" do
        expect(initializer.run).to be false
      end
    end

    context "when files exist and user presses enter" do
      let(:initializer) { described_class.new }

      before do
        FileUtils.mkdir_p("docs")
        allow($stdin).to receive(:gets).and_return("\n")
      end

      it "does not overwrite (defaults to no)" do
        initializer.run
        expect(File.exist?("docs/index.md")).to be false
      end

      it "returns false" do
        expect(initializer.run).to be false
      end
    end

    context "with force flag" do
      before do
        FileUtils.mkdir_p("docs")
        File.write("docs/existing.md", "existing content")
        allow($stdin).to receive(:gets)
      end

      let(:initializer) { described_class.new(nil, force: true) }

      it "skips confirmation prompt" do
        initializer.run
        expect($stdin).not_to have_received(:gets)
      end

      it "overwrites existing files" do
        initializer.run
        expect(File.exist?("docs/index.md")).to be true
      end

      it "returns true" do
        expect(initializer.run).to be true
      end
    end

    context "when only docyard.yml exists" do
      before do
        File.write("docyard.yml", "existing: config")
        allow($stdin).to receive(:gets).and_return("n\n")
      end

      let(:initializer) { described_class.new }

      it "prompts for overwrite confirmation" do
        initializer.run
        expect($stdout).to have_received(:puts).with(/Warning.*Existing files found/)
      end
    end
  end

  describe "project name transformation" do
    it "converts kebab-case to title case" do
      initializer = described_class.new("my-awesome-docs")
      initializer.run
      content = File.read("my-awesome-docs/docyard.yml")
      expect(content).to include('title: "My Awesome Docs"')
    end

    it "converts snake_case to title case" do
      initializer = described_class.new("my_awesome_docs")
      initializer.run
      content = File.read("my_awesome_docs/docyard.yml")
      expect(content).to include('title: "My Awesome Docs"')
    end

    it "uses default name when no project name given" do
      initializer = described_class.new
      initializer.run
      content = File.read("docyard.yml")
      expect(content).to include('title: "My Documentation"')
    end
  end

  describe "template content" do
    let(:initializer) { described_class.new }

    before { initializer.run }

    it "creates docyard.yml with configuration sections", :aggregate_failures do
      content = File.read("docyard.yml")
      expect(content).to include("title:")
      expect(content).to include("search:")
      expect(content).to include("build:")
    end

    it "creates _sidebar.yml with navigation items", :aggregate_failures do
      content = File.read("docs/_sidebar.yml")
      expect(content).to include("index:")
      expect(content).to include("getting-started:")
      expect(content).to include("components:")
    end

    it "creates index.md with hero section", :aggregate_failures do
      content = File.read("docs/index.md")
      expect(content).to include("template: splash")
      expect(content).to include("hero:")
    end

    it "creates getting-started.md with steps" do
      content = File.read("docs/getting-started.md")
      expect(content).to include(":::steps")
    end

    it "creates components.md with component examples", :aggregate_failures do
      content = File.read("docs/components.md")
      expect(content).to include(":::note")
      expect(content).to include(":::code-group")
      expect(content).to include(":::cards")
    end
  end
end
