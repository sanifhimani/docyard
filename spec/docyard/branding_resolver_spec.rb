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

    context "when no logo is configured and none exists in docs/public" do
      it "sets has_custom_logo to false" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:has_custom_logo]).to be false
        end
      end
    end

    context "when logo.svg exists in docs/public/" do
      before do
        create_file("docs/public/logo.svg", "<svg></svg>")
      end

      it "auto-detects the logo", :aggregate_failures do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:logo]).to eq("logo.svg")
          expect(result[:has_custom_logo]).to be true
        end
      end

      it "auto-detects dark variant when present", :aggregate_failures do
        create_file("docs/public/logo-dark.svg", "<svg>dark</svg>")

        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:logo]).to eq("logo.svg")
          expect(result[:logo_dark]).to eq("logo-dark.svg")
        end
      end
    end

    context "when logo.png exists in docs/public/ but not svg" do
      before do
        create_file("docs/public/logo.png", "png data")
      end

      it "auto-detects the png logo" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:logo]).to eq("logo.png")
        end
      end
    end

    context "when both logo.svg and logo.png exist in docs/public/" do
      before do
        create_file("docs/public/logo.svg", "<svg></svg>")
        create_file("docs/public/logo.png", "png data")
      end

      it "prefers svg over png" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:logo]).to eq("logo.svg")
        end
      end
    end

    context "when no logo exists in docs/public/" do
      it "falls back to Docyard default logo" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:logo]).to eq(Docyard::Constants::DEFAULT_LOGO_PATH)
        end
      end
    end

    context "when explicit logo config overrides auto-detection" do
      before do
        create_file("docs/public/logo.svg", "<svg></svg>")
        create_file("docs/public/custom-logo.svg", "<svg>custom</svg>")
        create_config(<<~YAML)
          branding:
            logo: "custom-logo.svg"
        YAML
      end

      it "uses the configured logo" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:logo]).to eq("custom-logo.svg")
        end
      end
    end

    context "when favicon.ico exists in docs/public/" do
      before do
        create_file("docs/public/favicon.ico", "icon data")
      end

      it "auto-detects the favicon" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:favicon]).to eq("favicon.ico")
        end
      end
    end

    context "when favicon.svg exists in docs/public/ but not ico" do
      before do
        create_file("docs/public/favicon.svg", "<svg></svg>")
      end

      it "auto-detects the svg favicon" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:favicon]).to eq("favicon.svg")
        end
      end
    end

    context "when favicon.png exists in docs/public/ but not ico or svg" do
      before do
        create_file("docs/public/favicon.png", "png data")
      end

      it "auto-detects the png favicon" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:favicon]).to eq("favicon.png")
        end
      end
    end

    context "when multiple favicon formats exist in docs/public/" do
      before do
        create_file("docs/public/favicon.ico", "ico data")
        create_file("docs/public/favicon.svg", "<svg></svg>")
        create_file("docs/public/favicon.png", "png data")
      end

      it "prefers ico over svg and png" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:favicon]).to eq("favicon.ico")
        end
      end
    end

    context "when no favicon exists in docs/public/" do
      it "returns nil" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:favicon]).to be_nil
        end
      end
    end

    context "when explicit favicon config overrides auto-detection" do
      before do
        create_file("docs/public/favicon.ico", "icon data")
        create_file("docs/public/custom-favicon.ico", "custom icon")
        create_config(<<~YAML)
          branding:
            favicon: "custom-favicon.ico"
        YAML
      end

      it "uses the configured favicon" do
        Dir.chdir(temp_dir) do
          result = resolver.resolve

          expect(result[:favicon]).to eq("custom-favicon.ico")
        end
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
