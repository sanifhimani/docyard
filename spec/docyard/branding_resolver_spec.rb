# frozen_string_literal: true

RSpec.describe Docyard::BrandingResolver do
  include_context "with temp directory"

  let(:config) { Docyard::Config.load(temp_dir) }
  let(:resolver) { described_class.new(config) }

  describe "#resolve" do
    context "with nil config" do
      let(:resolver) { described_class.new(nil) }

      it "returns default branding options", :aggregate_failures do
        result = resolver.resolve

        expect(result[:site_title]).to eq(Docyard::Constants::DEFAULT_SITE_TITLE)
        expect(result[:site_description]).to eq("")
        expect(result[:logo]).to eq(Docyard::Constants::DEFAULT_LOGO_PATH)
        expect(result[:logo_dark]).to eq(Docyard::Constants::DEFAULT_LOGO_DARK_PATH)
        expect(result[:favicon]).to be_nil
        expect(result[:credits]).to be true
        expect(result[:social]).to eq([])
      end
    end

    context "with default config" do
      it "returns default site title" do
        result = resolver.resolve

        expect(result[:site_title]).to eq("Documentation")
      end

      it "returns empty site description" do
        result = resolver.resolve

        expect(result[:site_description]).to eq("")
      end

      it "returns search enabled by default" do
        result = resolver.resolve

        expect(result[:search_enabled]).to be true
      end

      it "returns default search placeholder" do
        result = resolver.resolve

        expect(result[:search_placeholder]).to eq("Search...")
      end
    end

    context "with custom site config" do
      before do
        create_config(<<~YAML)
          title: "My Custom Docs"
          description: "Awesome documentation for my project"
        YAML
      end

      it "overrides site title" do
        result = resolver.resolve

        expect(result[:site_title]).to eq("My Custom Docs")
      end

      it "overrides site description" do
        result = resolver.resolve

        expect(result[:site_description]).to eq("Awesome documentation for my project")
      end
    end

    context "with custom branding config" do
      before do
        create_file("logo.svg", "<svg></svg>")
        create_file("favicon.ico", "icon")
        create_config(<<~YAML)
          branding:
            logo: "#{File.join(temp_dir, 'logo.svg')}"
            favicon: "#{File.join(temp_dir, 'favicon.ico')}"
        YAML
      end

      it "uses custom logo" do
        result = resolver.resolve

        expect(result[:logo]).to eq(File.join(temp_dir, "logo.svg"))
      end

      it "uses custom favicon" do
        result = resolver.resolve

        expect(result[:favicon]).to eq(File.join(temp_dir, "favicon.ico"))
      end
    end

    context "when only logo is set without dark variant" do
      before do
        create_file("logo.svg", "<svg></svg>")
        create_config(<<~YAML)
          branding:
            logo: "#{File.join(temp_dir, 'logo.svg')}"
        YAML
      end

      it "uses logo for both light and dark modes", :aggregate_failures do
        result = resolver.resolve

        expect(result[:logo]).to eq(File.join(temp_dir, "logo.svg"))
        expect(result[:logo_dark]).to eq(File.join(temp_dir, "logo.svg"))
      end

      it "sets has_custom_logo to true" do
        result = resolver.resolve

        expect(result[:has_custom_logo]).to be true
      end
    end

    context "when logo has a dark variant" do
      before do
        create_file("logo.svg", "<svg></svg>")
        create_file("logo-dark.svg", "<svg>dark</svg>")
        create_config(<<~YAML)
          branding:
            logo: "#{File.join(temp_dir, 'logo.svg')}"
        YAML
      end

      it "auto-detects the dark variant", :aggregate_failures do
        result = resolver.resolve

        expect(result[:logo]).to eq(File.join(temp_dir, "logo.svg"))
        expect(result[:logo_dark]).to eq(File.join(temp_dir, "logo-dark.svg"))
      end
    end

    context "when no logo is configured" do
      it "sets has_custom_logo to false" do
        result = resolver.resolve

        expect(result[:has_custom_logo]).to be false
      end
    end

    context "when search is disabled" do
      before do
        create_config(<<~YAML)
          search:
            enabled: false
        YAML
      end

      it "sets search_enabled to false" do
        result = resolver.resolve

        expect(result[:search_enabled]).to be false
      end
    end

    context "with custom search placeholder" do
      before do
        create_config(<<~YAML)
          search:
            placeholder: "Find something..."
        YAML
      end

      it "uses custom placeholder" do
        result = resolver.resolve

        expect(result[:search_placeholder]).to eq("Find something...")
      end
    end

    context "with default credits" do
      it "returns credits true by default" do
        result = resolver.resolve

        expect(result[:credits]).to be true
      end
    end

    context "when credits is disabled" do
      before do
        create_config(<<~YAML)
          branding:
            credits: false
        YAML
      end

      it "sets credits to false" do
        result = resolver.resolve

        expect(result[:credits]).to be false
      end
    end

    context "with default social links" do
      it "returns empty social array by default" do
        result = resolver.resolve

        expect(result[:social]).to eq([])
      end
    end

    context "when social links are configured" do
      before do
        create_config(<<~YAML)
          socials:
            github: https://github.com/docyard/docyard
            twitter: https://twitter.com/docyard
        YAML
      end

      it "normalizes social links to array", :aggregate_failures do
        result = resolver.resolve

        expect(result[:social]).to be_an(Array)
        expect(result[:social].length).to eq(2)
      end

      it "includes platform, url, and icon for each link", :aggregate_failures do
        result = resolver.resolve
        github = result[:social].find { |s| s[:platform] == "github" }

        expect(github[:platform]).to eq("github")
        expect(github[:url]).to eq("https://github.com/docyard/docyard")
        expect(github[:icon]).to eq("github")
      end
    end

    context "when social has empty values" do
      before do
        create_config(<<~YAML)
          socials:
            github: https://github.com/docyard/docyard
            twitter: ""
        YAML
      end

      it "filters out empty values", :aggregate_failures do
        result = resolver.resolve

        expect(result[:social].length).to eq(1)
        expect(result[:social][0][:platform]).to eq("github")
      end
    end
  end
end
