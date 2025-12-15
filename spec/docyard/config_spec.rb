# frozen_string_literal: true

RSpec.describe Docyard::Config do
  include_context "with temp directory"

  describe ".load" do
    context "when no config file exists" do
      it "returns config with default values", :aggregate_failures do
        config = described_class.load(temp_dir)

        expect(config.site.title).to eq("Documentation")
        expect(config.site.description).to eq("")
        expect(config.branding.logo).to be_nil
        expect(config.branding.appearance).to eq({ "logo" => true, "title" => true })
        expect(config.build.output_dir).to eq("dist")
        expect(config.build.base_url).to eq("/")
        expect(config.build.clean).to be true
        expect(config.sidebar.items).to eq([])
      end

      it "indicates that config file does not exist" do
        config = described_class.load(temp_dir)

        expect(config.file_exists?).to be false
      end
    end

    context "when config file exists" do
      it "loads and merges with defaults", :aggregate_failures do
        create_config(<<~YAML)
          site:
            title: "My Docs"
            description: "Awesome documentation"
        YAML

        config = described_class.load(temp_dir)

        expect(config.site.title).to eq("My Docs")
        expect(config.site.description).to eq("Awesome documentation")
        expect(config.build.output_dir).to eq("dist")
      end

      it "indicates that config file exists" do
        create_config("site:\n  title: Test")

        config = described_class.load(temp_dir)

        expect(config.file_exists?).to be true
      end

      it "deep merges nested config", :aggregate_failures do
        create_config("build:\n  output_dir: _site")

        config = described_class.load(temp_dir)

        expect(config.build.output_dir).to eq("_site")
        expect(config.build.base_url).to eq("/")
        expect(config.build.clean).to be true
      end

      it "handles empty config file" do
        create_config("")

        config = described_class.load(temp_dir)

        expect(config.site.title).to eq("Documentation")
      end
    end

    context "when config file has invalid YAML" do
      it "raises ConfigError with helpful message" do
        create_config("site:\n  title: 'unclosed string")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /Invalid YAML/)
      end
    end
  end

  describe "#site" do
    it "provides dot notation access to site config", :aggregate_failures do
      logo_path = create_file("logo.svg", "<svg></svg>")
      create_config("site:\n  title: 'Test Title'\n  logo: '#{logo_path}'")

      config = described_class.load(temp_dir)

      expect(config.site.title).to eq("Test Title")
      expect(config.site.logo).to eq(logo_path)
    end
  end

  describe "#build" do
    it "provides dot notation access to build config", :aggregate_failures do
      create_config(<<~YAML)
        build:
          output_dir: "public"
          base_url: "/docs/"
      YAML

      config = described_class.load(temp_dir)

      expect(config.build.output_dir).to eq("public")
      expect(config.build.base_url).to eq("/docs/")
    end
  end

  describe "#sidebar" do
    it "returns sidebar config" do
      create_config(<<~YAML)
        sidebar:
          items:
            - introduction
            - guide
      YAML

      config = described_class.load(temp_dir)

      expect(config.sidebar.items).to eq(%w[introduction guide])
    end

    it "returns empty items when sidebar not configured" do
      config = described_class.load(temp_dir)

      expect(config.sidebar.items).to eq([])
    end
  end

  describe "#markdown" do
    it "returns default lineNumbers as false" do
      config = described_class.load(temp_dir)

      expect(config.markdown.lineNumbers).to be false
    end

    it "returns configured lineNumbers value" do
      create_config("markdown:\n  lineNumbers: true")

      config = described_class.load(temp_dir)

      expect(config.markdown.lineNumbers).to be true
    end
  end

  describe "validation" do
    context "with invalid values" do
      it "raises ConfigError for invalid site.title" do
        create_config("site:\n  title: 123")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /site.title/)
      end

      it "raises ConfigError for invalid build.output_dir" do
        create_config("build:\n  output_dir: 123")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /build.output_dir/)
      end

      it "raises ConfigError for output_dir with slashes" do
        create_config("build:\n  output_dir: 'dist/folder'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /cannot contain slashes/)
      end

      it "raises ConfigError for base_url not starting with /" do
        create_config("build:\n  base_url: 'docs/'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /must start with/)
      end

      it "raises ConfigError for non-boolean build.clean" do
        create_config("build:\n  clean: 'yes'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /build.clean/)
      end

      it "raises ConfigError for non-boolean markdown.lineNumbers" do
        create_config("markdown:\n  lineNumbers: 'yes'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /markdown\.lineNumbers/)
      end

      it "raises ConfigError for non-boolean appearance.logo" do
        create_config("branding:\n  appearance:\n    logo: 'yes'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /branding\.appearance\.logo/)
      end

      it "raises ConfigError for non-boolean appearance.title" do
        create_config("branding:\n  appearance:\n    title: 1")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /branding\.appearance\.title/)
      end
    end

    context "with branding files" do
      it "raises ConfigError for missing logo file" do
        create_config("branding:\n  logo: 'nonexistent.svg'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /branding\.logo.*file not found/m)
      end

      it "validates successfully with existing logo file" do
        create_file("logo.svg", "<svg></svg>")
        create_config("branding:\n  logo: '#{File.join(temp_dir, 'logo.svg')}'")

        expect { described_class.load(temp_dir) }.not_to raise_error
      end

      it "validates successfully for http logo URL" do
        create_config("branding:\n  logo: 'http://example.com/logo.svg'")

        expect { described_class.load(temp_dir) }.not_to raise_error
      end

      it "validates successfully for https logo URL" do
        create_config("branding:\n  logo: 'https://cdn.example.com/logo.svg'")

        expect { described_class.load(temp_dir) }.not_to raise_error
      end

      it "validates successfully for https favicon URL" do
        create_config("branding:\n  favicon: 'https://cdn.example.com/favicon.ico'")

        expect { described_class.load(temp_dir) }.not_to raise_error
      end

      it "validates successfully for logo_dark URL" do
        create_config("branding:\n  logo_dark: 'https://cdn.example.com/logo-dark.svg'")

        expect { described_class.load(temp_dir) }.not_to raise_error
      end
    end

    context "with multiple errors" do
      it "reports all validation errors" do
        create_config("site:\n  title: 123\nbuild:\n  clean: 'yes'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /site\.title.*build\.clean/m)
      end
    end
  end
end
