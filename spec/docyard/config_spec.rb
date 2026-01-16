# frozen_string_literal: true

RSpec.describe Docyard::Config do
  include_context "with temp directory"

  describe ".load" do
    context "when no config file exists" do
      it "returns config with default values", :aggregate_failures do
        config = described_class.load(temp_dir)

        expect(config.title).to eq("Documentation")
        expect(config.description).to eq("")
        expect(config.branding.logo).to be_nil
        expect(config.branding.favicon).to be_nil
        expect(config.branding.credits).to be true
        expect(config.socials).to eq({})
        expect(config.tabs).to eq([])
        expect(config.build.output).to eq("dist")
        expect(config.build.base).to eq("/")
        expect(config.search.enabled).to be true
        expect(config.search.placeholder).to eq("Search...")
        expect(config.search.exclude).to eq([])
      end

      it "indicates that config file does not exist" do
        config = described_class.load(temp_dir)

        expect(config.file_exists?).to be false
      end
    end

    context "when config file exists" do
      it "loads and merges with defaults", :aggregate_failures do
        create_config(<<~YAML)
          title: "My Docs"
          description: "Awesome documentation"
        YAML

        config = described_class.load(temp_dir)

        expect(config.title).to eq("My Docs")
        expect(config.description).to eq("Awesome documentation")
        expect(config.build.output).to eq("dist")
      end

      it "indicates that config file exists" do
        create_config("title: Test")

        config = described_class.load(temp_dir)

        expect(config.file_exists?).to be true
      end

      it "deep merges nested config", :aggregate_failures do
        create_config("build:\n  output: _site")

        config = described_class.load(temp_dir)

        expect(config.build.output).to eq("_site")
        expect(config.build.base).to eq("/")
      end

      it "handles empty config file" do
        create_config("")

        config = described_class.load(temp_dir)

        expect(config.title).to eq("Documentation")
      end
    end

    context "when config file has invalid YAML" do
      it "raises ConfigError with helpful message" do
        create_config("title: 'unclosed string")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /Invalid YAML/)
      end
    end
  end

  describe "#title and #description" do
    it "provides flat access to site identity", :aggregate_failures do
      create_config("title: 'Test Title'\ndescription: 'Test description'")

      config = described_class.load(temp_dir)

      expect(config.title).to eq("Test Title")
      expect(config.description).to eq("Test description")
    end
  end

  describe "#url, #og_image, and #twitter" do
    context "when not configured" do
      it "returns nil for all OG-related fields", :aggregate_failures do
        config = described_class.load(temp_dir)

        expect(config.url).to be_nil
        expect(config.og_image).to be_nil
        expect(config.twitter).to be_nil
      end
    end

    context "when configured" do
      it "provides access to OG config", :aggregate_failures do
        create_config(<<~YAML)
          url: "https://docs.example.com"
          og_image: "/images/og.png"
          twitter: "docyard"
        YAML

        config = described_class.load(temp_dir)

        expect(config.url).to eq("https://docs.example.com")
        expect(config.og_image).to eq("/images/og.png")
        expect(config.twitter).to eq("docyard")
      end
    end
  end

  describe "#branding" do
    it "provides access to branding config", :aggregate_failures do
      logo_path = create_file("logo.svg", "<svg></svg>")
      favicon_path = create_file("favicon.ico", "icon")
      create_config(<<~YAML)
        branding:
          logo: '#{logo_path}'
          favicon: '#{favicon_path}'
          credits: false
      YAML

      config = described_class.load(temp_dir)

      expect(config.branding.logo).to eq(logo_path)
      expect(config.branding.favicon).to eq(favicon_path)
      expect(config.branding.credits).to be false
    end
  end

  describe "#socials" do
    it "returns social links hash" do
      create_config(<<~YAML)
        socials:
          github: https://github.com/user/repo
          discord: https://discord.gg/invite
      YAML

      config = described_class.load(temp_dir)

      expect(config.socials).to eq({
                                     "github" => "https://github.com/user/repo",
                                     "discord" => "https://discord.gg/invite"
                                   })
    end

    it "returns empty hash when not configured" do
      config = described_class.load(temp_dir)

      expect(config.socials).to eq({})
    end
  end

  describe "#tabs" do
    it "returns tabs configuration", :aggregate_failures do
      create_config(<<~YAML)
        tabs:
          - text: Guide
            href: /guide
          - text: API
            href: /api
          - text: Blog
            href: https://blog.example.com
            external: true
      YAML

      config = described_class.load(temp_dir)
      expect(config.tabs.size).to eq(3)
      expect(config.tabs.first).to eq({ "text" => "Guide", "href" => "/guide" })
    end

    it "returns empty array when not configured" do
      config = described_class.load(temp_dir)

      expect(config.tabs).to eq([])
    end
  end

  describe "#build" do
    it "provides dot notation access to build config", :aggregate_failures do
      create_config(<<~YAML)
        build:
          output: "public"
          base: "/docs/"
      YAML

      config = described_class.load(temp_dir)

      expect(config.build.output).to eq("public")
      expect(config.build.base).to eq("/docs/")
    end
  end

  describe "#search" do
    it "provides access to search config", :aggregate_failures do
      create_config(<<~YAML)
        search:
          enabled: false
          placeholder: "Find docs..."
          exclude:
            - /drafts/*
            - /internal/*
      YAML

      config = described_class.load(temp_dir)

      expect(config.search.enabled).to be false
      expect(config.search.placeholder).to eq("Find docs...")
      expect(config.search.exclude).to eq(["/drafts/*", "/internal/*"])
    end
  end

  describe "#announcement" do
    it "returns nil when not configured" do
      config = described_class.load(temp_dir)

      expect(config.announcement).to be_nil
    end

    it "provides access to announcement config", :aggregate_failures do
      create_config(<<~YAML)
        announcement:
          text: "New version available!"
          link: "/changelog"
          dismissible: true
      YAML

      config = described_class.load(temp_dir)

      expect(config.announcement.text).to eq("New version available!")
      expect(config.announcement.link).to eq("/changelog")
      expect(config.announcement.dismissible).to be true
    end
  end

  describe "validation" do
    context "with invalid values" do
      it "raises ConfigError for invalid title" do
        create_config("title: 123")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /title/)
      end

      it "raises ConfigError for invalid build.output" do
        create_config("build:\n  output: 123")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /build.output/)
      end

      it "raises ConfigError for output with slashes" do
        create_config("build:\n  output: 'dist/folder'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /cannot contain slashes/)
      end

      it "raises ConfigError for base not starting with /" do
        create_config("build:\n  base: 'docs/'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /must start with/)
      end

      it "raises ConfigError for non-boolean branding.credits" do
        create_config("branding:\n  credits: 'yes'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /branding\.credits/)
      end

      it "raises ConfigError for non-boolean search.enabled" do
        create_config("search:\n  enabled: 'yes'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /search\.enabled/)
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
    end

    context "with multiple errors" do
      it "reports all validation errors" do
        create_config("title: 123\nbuild:\n  base: 'no-slash'")

        expect { described_class.load(temp_dir) }
          .to raise_error(Docyard::ConfigError, /title.*build\.base/m)
      end
    end
  end
end
