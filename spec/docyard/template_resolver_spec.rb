# frozen_string_literal: true

RSpec.describe Docyard::TemplateResolver do
  describe "#landing?" do
    it "returns false for empty frontmatter" do
      resolver = described_class.new({})
      expect(resolver.landing?).to be false
    end

    it "returns false for nil frontmatter" do
      resolver = described_class.new(nil)
      expect(resolver.landing?).to be false
    end

    it "returns true when landing key is present with content" do
      resolver = described_class.new({ "landing" => { "hero" => { "title" => "Test" } } })
      expect(resolver.landing?).to be true
    end

    it "returns false when landing is empty hash" do
      resolver = described_class.new({ "landing" => {} })
      expect(resolver.landing?).to be false
    end

    it "returns true when landing comes from site_config" do
      resolver = described_class.new({}, { "landing" => { "hero" => { "title" => "Test" } } })
      expect(resolver.landing?).to be true
    end

    it "prefers frontmatter landing over site_config" do
      frontmatter = { "landing" => { "hero" => { "title" => "Frontmatter" } } }
      site_config = { "landing" => { "hero" => { "title" => "Site" } } }
      resolver = described_class.new(frontmatter, site_config)
      expect(resolver.hero_config[:title]).to eq("Frontmatter")
    end
  end

  describe "#template" do
    it "returns default for empty frontmatter" do
      resolver = described_class.new({})
      expect(resolver.template).to eq("default")
    end

    it "returns default for nil frontmatter" do
      resolver = described_class.new(nil)
      expect(resolver.template).to eq("default")
    end

    it "returns splash when landing is present" do
      resolver = described_class.new({ "landing" => { "hero" => { "title" => "Test" } } })
      expect(resolver.template).to eq("splash")
    end
  end

  describe "#show_sidebar?" do
    it "returns true for default template" do
      resolver = described_class.new({})
      expect(resolver.show_sidebar?).to be true
    end

    it "returns false for landing page by default" do
      resolver = described_class.new({ "landing" => { "hero" => { "title" => "Test" } } })
      expect(resolver.show_sidebar?).to be false
    end

    it "returns true when landing sidebar is explicitly enabled" do
      resolver = described_class.new({ "landing" => { "sidebar" => true, "hero" => { "title" => "Test" } } })
      expect(resolver.show_sidebar?).to be true
    end

    it "returns false when landing sidebar is explicitly disabled" do
      resolver = described_class.new({ "landing" => { "sidebar" => false, "hero" => { "title" => "Test" } } })
      expect(resolver.show_sidebar?).to be false
    end
  end

  describe "#show_toc?" do
    it "returns true for default template" do
      resolver = described_class.new({})
      expect(resolver.show_toc?).to be true
    end

    it "always returns false for landing pages" do
      resolver = described_class.new({ "landing" => { "hero" => { "title" => "Test" } } })
      expect(resolver.show_toc?).to be false
    end
  end

  describe "#hero_config" do
    it "returns nil for non-landing pages" do
      resolver = described_class.new({ "hero" => { "title" => "Test" } })
      expect(resolver.hero_config).to be_nil
    end

    it "returns nil when hero is not a hash" do
      resolver = described_class.new({ "landing" => { "hero" => "invalid" } })
      expect(resolver.hero_config).to be_nil
    end

    it "returns symbolized hero config for landing page", :aggregate_failures do
      hero = { "title" => "My Title", "tagline" => "My Tagline", "badge" => "New!",
               "image" => { "src" => "/hero.png", "alt" => "Hero image" },
               "actions" => [{ "text" => "Get Started", "link" => "/start" },
                             { "text" => "GitHub", "link" => "https://github.com", "variant" => "secondary" }] }
      resolver = described_class.new({ "landing" => { "hero" => hero } })
      config = resolver.hero_config

      expect(config).to include(title: "My Title", tagline: "My Tagline", badge: "New!")
      expect(config[:image]).to include(src: "/hero.png", alt: "Hero image")
      expect(config[:actions].length).to eq(2)
      expect(config[:actions][0]).to include(text: "Get Started", variant: "primary")
      expect(config[:actions][1][:variant]).to eq("secondary")
    end

    it "uses default background when not specified" do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test" }
        }
      }

      resolver = described_class.new(frontmatter)
      config = resolver.hero_config

      expect(config[:background]).to eq("grid")
    end

    it "validates background values" do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test", "background" => "invalid" }
        }
      }

      resolver = described_class.new(frontmatter)
      config = resolver.hero_config

      expect(config[:background]).to eq("grid")
    end

    it "accepts valid background values" do
      %w[grid glow mesh].each do |bg|
        frontmatter = {
          "landing" => {
            "hero" => { "title" => "Test", "background" => bg }
          }
        }

        resolver = described_class.new(frontmatter)
        config = resolver.hero_config

        expect(config[:background]).to eq(bg)
      end
    end

    it "includes gradient option with default true" do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test" }
        }
      }

      resolver = described_class.new(frontmatter)
      config = resolver.hero_config

      expect(config[:gradient]).to be true
    end

    it "handles missing image" do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test" }
        }
      }

      resolver = described_class.new(frontmatter)
      config = resolver.hero_config

      expect(config[:image]).to be_nil
    end

    it "handles missing actions" do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test" }
        }
      }

      resolver = described_class.new(frontmatter)
      config = resolver.hero_config

      expect(config[:actions]).to be_nil
    end
  end

  describe "#features_config" do
    it "returns nil for non-landing pages" do
      resolver = described_class.new({ "features" => [{ "title" => "Test" }] })
      expect(resolver.features_config).to be_nil
    end

    it "returns nil when features is not an array" do
      resolver = described_class.new({ "landing" => { "features" => "invalid" } })
      expect(resolver.features_config).to be_nil
    end

    it "returns symbolized features for landing page", :aggregate_failures do
      features_data = [
        { "title" => "Feature 1", "description" => "Desc 1", "icon" => "rocket-launch", "color" => "purple" },
        { "title" => "Feature 2", "description" => "Desc 2", "size" => "large" }
      ]
      resolver = described_class.new({ "landing" => { "features" => features_data } })
      features = resolver.features_config

      expect(features.length).to eq(2)
      expect(features[0]).to include(title: "Feature 1", icon: "rocket-launch", color: "purple")
      expect(features[1]).to include(size: "large")
      expect(features[1][:icon]).to be_nil
    end

    it "handles non-hash items in features array", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "features" => [
            { "title" => "Valid" },
            "invalid"
          ]
        }
      }

      resolver = described_class.new(frontmatter)
      features = resolver.features_config

      expect(features.length).to eq(2)
      expect(features[0][:title]).to eq("Valid")
      expect(features[1]).to eq({})
    end
  end

  describe "#features_header_config" do
    it "returns nil for non-landing pages" do
      resolver = described_class.new({ "features_header" => { "title" => "Test" } })
      expect(resolver.features_header_config).to be_nil
    end

    it "returns nil when features_header is not a hash" do
      resolver = described_class.new({ "landing" => { "features_header" => "invalid" } })
      expect(resolver.features_header_config).to be_nil
    end

    it "returns symbolized features_header for landing page", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test" },
          "features_header" => {
            "label" => "Features",
            "title" => "Everything you need",
            "description" => "Built for developers"
          }
        }
      }

      resolver = described_class.new(frontmatter)
      header = resolver.features_header_config

      expect(header[:label]).to eq("Features")
      expect(header[:title]).to eq("Everything you need")
      expect(header[:description]).to eq("Built for developers")
    end

    it "handles missing fields", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test" },
          "features_header" => {
            "title" => "Only title"
          }
        }
      }

      resolver = described_class.new(frontmatter)
      header = resolver.features_header_config

      expect(header[:title]).to eq("Only title")
      expect(header[:label]).to be_nil
      expect(header[:description]).to be_nil
    end
  end

  describe "feature link support" do
    it "includes link in feature config" do
      frontmatter = {
        "landing" => {
          "features" => [
            { "title" => "Feature", "link" => "/docs/feature" }
          ]
        }
      }

      resolver = described_class.new(frontmatter)
      features = resolver.features_config

      expect(features[0][:link]).to eq("/docs/feature")
    end

    it "omits link when not provided" do
      frontmatter = {
        "landing" => {
          "features" => [
            { "title" => "Feature" }
          ]
        }
      }

      resolver = described_class.new(frontmatter)
      features = resolver.features_config

      expect(features[0]).not_to have_key(:link)
    end

    it "includes custom link_text" do
      frontmatter = {
        "landing" => {
          "features" => [
            { "title" => "Feature", "link" => "/docs", "link_text" => "Read the docs" }
          ]
        }
      }

      resolver = described_class.new(frontmatter)
      features = resolver.features_config

      expect(features[0][:link_text]).to eq("Read the docs")
    end

    it "includes target and rel attributes", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "features" => [
            { "title" => "Feature", "link" => "/docs", "target" => "_blank", "rel" => "noopener" }
          ]
        }
      }

      resolver = described_class.new(frontmatter)
      features = resolver.features_config

      expect(features[0][:target]).to eq("_blank")
      expect(features[0][:rel]).to eq("noopener")
    end
  end

  describe "action link attributes" do
    it "includes target and rel on actions", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "hero" => {
            "title" => "Test",
            "actions" => [
              { "text" => "Docs", "link" => "/docs", "target" => "_self", "rel" => "nofollow" }
            ]
          }
        }
      }

      resolver = described_class.new(frontmatter)
      actions = resolver.hero_config[:actions]

      expect(actions[0][:target]).to eq("_self")
      expect(actions[0][:rel]).to eq("nofollow")
    end

    it "omits target and rel when not provided", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "hero" => {
            "title" => "Test",
            "actions" => [
              { "text" => "Docs", "link" => "/docs" }
            ]
          }
        }
      }

      resolver = described_class.new(frontmatter)
      actions = resolver.hero_config[:actions]

      expect(actions[0]).not_to have_key(:target)
      expect(actions[0]).not_to have_key(:rel)
    end
  end

  describe "theme-aware hero images" do
    it "supports light/dark image variants", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "hero" => {
            "title" => "Test",
            "image" => { "light" => "/hero-light.png", "dark" => "/hero-dark.png", "alt" => "Hero image" }
          }
        }
      }
      resolver = described_class.new(frontmatter)
      image = resolver.hero_config[:image]

      expect(image[:light]).to eq("/hero-light.png")
      expect(image[:dark]).to eq("/hero-dark.png")
      expect(image[:alt]).to eq("Hero image")
      expect(image).not_to have_key(:src)
    end

    it "supports single src image (backward compatible)", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "hero" => {
            "title" => "Test",
            "image" => { "src" => "/hero.png", "alt" => "Hero image" }
          }
        }
      }
      resolver = described_class.new(frontmatter)
      image = resolver.hero_config[:image]

      expect(image[:src]).to eq("/hero.png")
      expect(image[:alt]).to eq("Hero image")
      expect(image).not_to have_key(:light)
      expect(image).not_to have_key(:dark)
    end

    it "supports only light image", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test", "image" => { "light" => "/hero-light.png" } }
        }
      }
      resolver = described_class.new(frontmatter)
      image = resolver.hero_config[:image]

      expect(image[:light]).to eq("/hero-light.png")
      expect(image).not_to have_key(:dark)
    end

    it "supports only dark image", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test", "image" => { "dark" => "/hero-dark.png" } }
        }
      }
      resolver = described_class.new(frontmatter)
      image = resolver.hero_config[:image]

      expect(image[:dark]).to eq("/hero-dark.png")
      expect(image).not_to have_key(:light)
    end
  end

  describe "#footer_config" do
    it "returns nil for non-landing pages" do
      resolver = described_class.new({ "footer" => { "links" => [] } })
      expect(resolver.footer_config).to be_nil
    end

    it "returns nil when footer is not a hash" do
      resolver = described_class.new({ "landing" => { "hero" => { "title" => "Test" }, "footer" => "invalid" } })
      expect(resolver.footer_config).to be_nil
    end

    it "returns symbolized footer config for landing page", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test" },
          "footer" => { "links" => [{ "text" => "Privacy", "link" => "/privacy" }] }
        }
      }
      resolver = described_class.new(frontmatter)
      config = resolver.footer_config

      expect(config[:links]).to be_an(Array)
      expect(config[:links].length).to eq(1)
      expect(config[:links][0]).to eq({ text: "Privacy", link: "/privacy" })
    end

    it "handles missing links" do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test" },
          "footer" => {}
        }
      }
      resolver = described_class.new(frontmatter)
      config = resolver.footer_config

      expect(config[:links]).to be_nil
    end

    it "handles non-array links" do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test" },
          "footer" => { "links" => "invalid" }
        }
      }
      resolver = described_class.new(frontmatter)
      config = resolver.footer_config

      expect(config[:links]).to be_nil
    end

    it "filters out non-hash items in links", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "hero" => { "title" => "Test" },
          "footer" => {
            "links" => [
              { "text" => "Valid", "link" => "/valid" },
              "invalid"
            ]
          }
        }
      }
      resolver = described_class.new(frontmatter)
      config = resolver.footer_config

      expect(config[:links].length).to eq(1)
      expect(config[:links][0][:text]).to eq("Valid")
    end
  end

  describe "#to_options" do
    it "returns complete options hash for landing page", :aggregate_failures do
      landing = { "hero" => { "title" => "Test" }, "features" => [{ "title" => "Feature" }],
                  "features_header" => { "title" => "Header" } }
      resolver = described_class.new({ "landing" => landing })
      options = resolver.to_options

      expect(options).to include(template: "splash", landing: true, show_sidebar: false, show_toc: false)
      expect(options[:hero]).to be_a(Hash)
      expect(options[:features]).to be_an(Array)
      expect(options[:features_header]).to include(title: "Header")
    end

    it "returns default options for empty frontmatter", :aggregate_failures do
      resolver = described_class.new({})
      options = resolver.to_options

      expect(options[:template]).to eq("default")
      expect(options[:landing]).to be false
      expect(options[:show_sidebar]).to be true
      expect(options[:show_toc]).to be true
      expect(options[:hero]).to be_nil
      expect(options[:features]).to be_nil
    end

    it "returns landing with sidebar enabled", :aggregate_failures do
      frontmatter = {
        "landing" => {
          "sidebar" => true,
          "hero" => { "title" => "Test" }
        }
      }

      resolver = described_class.new(frontmatter)
      options = resolver.to_options

      expect(options[:template]).to eq("splash")
      expect(options[:landing]).to be true
      expect(options[:show_sidebar]).to be true
    end
  end
end
