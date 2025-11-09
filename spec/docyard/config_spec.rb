# frozen_string_literal: true

RSpec.describe Docyard::Config do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe ".load" do
    context "when no config file exists" do
      it "returns config with default values", :aggregate_failures do
        config = described_class.load(temp_dir)

        expect(config.site.title).to eq("Documentation")
        expect(config.site.description).to eq("")
        expect(config.site.logo).to be_nil
        expect(config.build.output_dir).to eq("dist")
        expect(config.build.base_url).to eq("/")
        expect(config.build.clean).to be true
        expect(config.sidebar).to be_nil
      end

      it "indicates that config file does not exist" do
        config = described_class.load(temp_dir)

        expect(config.file_exists?).to be false
      end
    end

    context "when config file exists" do
      it "loads and merges with defaults", :aggregate_failures do
        config_content = <<~YAML
          site:
            title: "My Docs"
            description: "Awesome documentation"
        YAML
        File.write(File.join(temp_dir, "docyard.yml"), config_content)

        config = described_class.load(temp_dir)

        expect(config.site.title).to eq("My Docs")
        expect(config.site.description).to eq("Awesome documentation")
        expect(config.build.output_dir).to eq("dist")
      end

      it "indicates that config file exists" do
        File.write(File.join(temp_dir, "docyard.yml"), "site:\n  title: Test")

        config = described_class.load(temp_dir)

        expect(config.file_exists?).to be true
      end

      it "deep merges nested config", :aggregate_failures do
        config_content = <<~YAML
          build:
            output_dir: "_site"
        YAML
        File.write(File.join(temp_dir, "docyard.yml"), config_content)

        config = described_class.load(temp_dir)

        expect(config.build.output_dir).to eq("_site")
        expect(config.build.base_url).to eq("/")
        expect(config.build.clean).to be true
      end

      it "handles empty config file", :aggregate_failures do
        File.write(File.join(temp_dir, "docyard.yml"), "")

        config = described_class.load(temp_dir)

        expect(config.site.title).to eq("Documentation")
        expect(config.build.output_dir).to eq("dist")
      end
    end

    context "when config file has invalid YAML" do
      it "raises ConfigError with helpful message" do
        invalid_yaml = "site:\n  title: 'unclosed string"
        File.write(File.join(temp_dir, "docyard.yml"), invalid_yaml)

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /Invalid YAML/)
      end
    end
  end

  describe "#site" do
    it "provides dot notation access to site config", :aggregate_failures do
      logo_path = File.join(temp_dir, "logo.svg")
      File.write(logo_path, "<svg></svg>")
      File.write(File.join(temp_dir, "docyard.yml"), "site:\n  title: 'Test Title'\n  logo: '#{logo_path}'")

      config = described_class.load(temp_dir)

      expect(config.site.title).to eq("Test Title")
      expect(config.site.logo).to eq(logo_path)
    end
  end

  describe "#build" do
    it "provides dot notation access to build config", :aggregate_failures do
      config_content = <<~YAML
        build:
          output_dir: "public"
          base_url: "/docs/"
      YAML
      File.write(File.join(temp_dir, "docyard.yml"), config_content)

      config = described_class.load(temp_dir)

      expect(config.build.output_dir).to eq("public")
      expect(config.build.base_url).to eq("/docs/")
    end
  end

  describe "#sidebar" do
    it "returns sidebar config" do
      config_content = <<~YAML
        sidebar:
          - introduction
          - guide
      YAML
      File.write(File.join(temp_dir, "docyard.yml"), config_content)

      config = described_class.load(temp_dir)

      expect(config.sidebar).to eq(%w[introduction guide])
    end

    it "returns nil when sidebar not configured" do
      config = described_class.load(temp_dir)

      expect(config.sidebar).to be_nil
    end
  end

  describe "validation" do
    context "with invalid site.title" do
      it "raises ConfigError" do
        config_content = "site:\n  title: 123"
        File.write(File.join(temp_dir, "docyard.yml"), config_content)

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /site.title/)
      end
    end

    context "with invalid build.output_dir" do
      it "raises ConfigError for non-string value" do
        config_content = "build:\n  output_dir: 123"
        File.write(File.join(temp_dir, "docyard.yml"), config_content)

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /build.output_dir/)
      end

      it "raises ConfigError for value with slashes" do
        config_content = "build:\n  output_dir: 'dist/folder'"
        File.write(File.join(temp_dir, "docyard.yml"), config_content)

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /cannot contain slashes/)
      end
    end

    context "with invalid build.base_url" do
      it "raises ConfigError when not starting with /" do
        config_content = "build:\n  base_url: 'docs/'"
        File.write(File.join(temp_dir, "docyard.yml"), config_content)

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /must start with/)
      end
    end

    context "with invalid build.clean" do
      it "raises ConfigError for non-boolean value" do
        config_content = "build:\n  clean: 'yes'"
        File.write(File.join(temp_dir, "docyard.yml"), config_content)

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /build.clean/)
      end
    end

    context "with missing logo file" do
      it "raises ConfigError" do
        config_content = "site:\n  logo: 'nonexistent.svg'"
        File.write(File.join(temp_dir, "docyard.yml"), config_content)

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /site\.logo.*file not found/m)
      end
    end

    context "with existing logo file" do
      it "validates successfully" do
        logo_path = File.join(temp_dir, "logo.svg")
        File.write(logo_path, "<svg></svg>")

        config_content = "site:\n  logo: '#{logo_path}'"
        File.write(File.join(temp_dir, "docyard.yml"), config_content)

        expect { described_class.load(temp_dir) }.not_to raise_error
      end
    end

    context "with multiple errors" do
      it "reports site.title error" do
        config_yaml = "site:\n  title: 123\nbuild:\n  clean: 'yes'"
        File.write(File.join(temp_dir, "docyard.yml"), config_yaml)

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /site\.title/)
      end

      it "reports build.clean error" do
        config_yaml = "site:\n  title: 123\nbuild:\n  clean: 'yes'"
        File.write(File.join(temp_dir, "docyard.yml"), config_yaml)

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /build\.clean/)
      end
    end
  end
end
