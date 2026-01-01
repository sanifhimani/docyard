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
        expect(result[:display_logo]).to be true
        expect(result[:display_title]).to be true
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

        expect(result[:search_placeholder]).to eq("Search documentation...")
      end
    end

    context "with custom site config" do
      before do
        create_config(<<~YAML)
          site:
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
        create_file("logo-dark.svg", "<svg></svg>")
        create_file("favicon.ico", "icon")
        create_config(<<~YAML)
          branding:
            logo: "#{File.join(temp_dir, 'logo.svg')}"
            logo_dark: "#{File.join(temp_dir, 'logo-dark.svg')}"
            favicon: "#{File.join(temp_dir, 'favicon.ico')}"
        YAML
      end

      it "uses custom logo" do
        result = resolver.resolve

        expect(result[:logo]).to eq(File.join(temp_dir, "logo.svg"))
      end

      it "uses custom logo_dark" do
        result = resolver.resolve

        expect(result[:logo_dark]).to eq(File.join(temp_dir, "logo-dark.svg"))
      end

      it "uses custom favicon" do
        result = resolver.resolve

        expect(result[:favicon]).to eq(File.join(temp_dir, "favicon.ico"))
      end
    end

    context "when only logo is set" do
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
    end

    context "when only logo_dark is set" do
      before do
        create_file("logo-dark.svg", "<svg></svg>")
        create_config(<<~YAML)
          branding:
            logo_dark: "#{File.join(temp_dir, 'logo-dark.svg')}"
        YAML
      end

      it "uses logo_dark for both modes", :aggregate_failures do
        result = resolver.resolve

        expect(result[:logo]).to eq(File.join(temp_dir, "logo-dark.svg"))
        expect(result[:logo_dark]).to eq(File.join(temp_dir, "logo-dark.svg"))
      end
    end

    context "when logo display is disabled" do
      before do
        create_config(<<~YAML)
          branding:
            appearance:
              logo: false
        YAML
      end

      it "sets display_logo to false" do
        result = resolver.resolve

        expect(result[:display_logo]).to be false
      end
    end

    context "when title display is disabled" do
      before do
        create_config(<<~YAML)
          branding:
            appearance:
              title: false
        YAML
      end

      it "sets display_title to false" do
        result = resolver.resolve

        expect(result[:display_title]).to be false
      end
    end

    context "when both appearance options are enabled explicitly" do
      before do
        create_config(<<~YAML)
          branding:
            appearance:
              logo: true
              title: true
        YAML
      end

      it "sets both to true", :aggregate_failures do
        result = resolver.resolve

        expect(result[:display_logo]).to be true
        expect(result[:display_title]).to be true
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
  end
end
