# frozen_string_literal: true

RSpec.describe Docyard::Config::Validator do
  include_context "with temp directory"

  let(:base_config) do
    {
      "title" => "Documentation",
      "description" => "",
      "branding" => { "logo" => nil, "favicon" => nil, "credits" => true },
      "socials" => {},
      "tabs" => [],
      "build" => { "output" => "dist", "base" => "/" },
      "search" => { "enabled" => true, "placeholder" => "Search...", "exclude" => [] }
    }
  end

  def valid_config(overrides = {})
    deep_merge(base_config, overrides)
  end

  def deep_merge(hash1, hash2)
    hash1.merge(hash2) do |_key, v1, v2|
      if v2.nil?
        v1
      elsif v1.is_a?(Hash) && v2.is_a?(Hash)
        deep_merge(v1, v2)
      else
        v2
      end
    end
  end

  describe "#validate!" do
    context "with valid config" do
      it "does not raise for default config" do
        validator = described_class.new(valid_config)

        expect { validator.validate! }.not_to raise_error
      end

      it "does not raise for valid string values" do
        config = valid_config(
          "title" => "My Docs",
          "description" => "Documentation",
          "build" => { "output" => "public", "base" => "/docs/" }
        )
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end

      it "does not raise for valid boolean values" do
        config = valid_config(
          "branding" => { "credits" => false },
          "search" => { "enabled" => false }
        )
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end
    end

    context "with invalid top-level fields" do
      it "raises ConfigError for non-string title" do
        config = valid_config("title" => 123)
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /title.*must be a string/m)
      end

      it "raises ConfigError for non-string description" do
        config = valid_config("description" => ["array"])
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /description.*must be a string/m)
      end
    end

    context "with invalid build section" do
      it "raises ConfigError for non-string output" do
        config = valid_config("build" => { "output" => 123 })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /build\.output.*must be a string/m)
      end

      it "raises ConfigError for output with forward slash" do
        config = valid_config("build" => { "output" => "dist/folder" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /build\.output.*cannot contain slashes/m)
      end

      it "raises ConfigError for output with backslash" do
        config = valid_config("build" => { "output" => 'dist\folder' })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /build\.output.*cannot contain slashes/m)
      end

      it "raises ConfigError for base not starting with slash" do
        config = valid_config("build" => { "base" => "docs/" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /build\.base.*must start with/m)
      end
    end

    context "with invalid branding section" do
      it "raises ConfigError for non-string logo" do
        config = valid_config("branding" => { "logo" => 123 })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /branding\.logo.*must be a file path/m)
      end

      it "raises ConfigError for missing logo file" do
        config = valid_config("branding" => { "logo" => "nonexistent.svg" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /branding\.logo.*file not found/m)
      end

      it "does not raise for http URL logo" do
        config = valid_config("branding" => { "logo" => "http://example.com/logo.svg" })
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end

      it "does not raise for https URL logo" do
        config = valid_config("branding" => { "logo" => "https://example.com/logo.svg" })
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end

      it "raises ConfigError for non-boolean credits" do
        config = valid_config("branding" => { "credits" => "yes" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /branding\.credits.*must be true or false/m)
      end
    end

    context "with invalid socials section" do
      it "raises ConfigError for non-hash socials" do
        config = valid_config("socials" => "string")
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /socials.*must be a hash/m)
      end

      it "raises ConfigError for non-string social URL" do
        config = valid_config("socials" => { "github" => 123 })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /socials\.github.*must be a URL/m)
      end

      it "raises ConfigError for non-array custom socials" do
        config = valid_config("socials" => { "custom" => "string" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /socials\.custom.*must be an array/m)
      end
    end

    context "with invalid tabs section" do
      it "raises ConfigError for non-array tabs" do
        config = valid_config("tabs" => "string")
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /tabs.*must be an array/m)
      end

      it "raises ConfigError for non-string tab text" do
        config = valid_config("tabs" => [{ "text" => 123, "href" => "/guide" }])
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /tabs\[0\]\.text.*must be a string/m)
      end

      it "raises ConfigError for non-boolean external" do
        config = valid_config("tabs" => [{ "text" => "Blog", "href" => "http://blog.example.com",
                                           "external" => "yes" }])
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /tabs\[0\]\.external.*must be true or false/m)
      end
    end

    context "with invalid search section" do
      it "raises ConfigError for non-boolean enabled" do
        config = valid_config("search" => { "enabled" => "yes" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /search\.enabled.*must be true or false/m)
      end

      it "raises ConfigError for non-array exclude" do
        config = valid_config("search" => { "exclude" => "string" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /search\.exclude.*must be an array/m)
      end
    end

    context "with multiple errors" do
      it "reports all validation errors", :aggregate_failures do
        config = valid_config(
          "title" => 123,
          "build" => { "base" => "no-slash" }
        )
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError) do |error|
            expect(error.message).to include("title")
            expect(error.message).to include("build.base")
          end
      end

      it "formats error messages with field, error, got, and fix", :aggregate_failures do
        config = valid_config("title" => 123)
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError) do |error|
            expect(error.message).to include("Field: title")
            expect(error.message).to include("Error: must be a string")
            expect(error.message).to include("Got: Integer")
            expect(error.message).to include("Fix:")
          end
      end
    end

    context "with existing branding files" do
      it "validates successfully for existing logo file" do
        logo_path = create_file("logo.svg", "<svg></svg>")
        config = valid_config("branding" => { "logo" => logo_path })
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end

      it "validates successfully for URL paths without file existence check" do
        config = valid_config("branding" => { "logo" => "https://cdn.example.com/logo.svg" })
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end
    end

    context "with valid navigation section" do
      it "does not raise for valid CTA items" do
        config = valid_config(
          "navigation" => {
            "cta" => [
              { "text" => "Get Started", "href" => "/guide" },
              { "text" => "GitHub", "href" => "https://github.com", "variant" => "secondary", "external" => true }
            ]
          }
        )
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end

      it "does not raise for empty CTA array" do
        config = valid_config("navigation" => { "cta" => [] })
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end
    end

    context "with invalid navigation section" do
      it "raises ConfigError for non-array cta" do
        config = valid_config("navigation" => { "cta" => "string" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /navigation\.cta.*must be an array/m)
      end

      it "raises ConfigError for non-string CTA text" do
        config = valid_config("navigation" => { "cta" => [{ "text" => 123, "href" => "/guide" }] })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /navigation\.cta\[0\]\.text.*must be a string/m)
      end

      it "raises ConfigError for non-string CTA href" do
        config = valid_config("navigation" => { "cta" => [{ "text" => "Get Started", "href" => 123 }] })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /navigation\.cta\[0\]\.href.*must be a string/m)
      end

      it "raises ConfigError for invalid variant" do
        config = valid_config(
          "navigation" => { "cta" => [{ "text" => "CTA", "href" => "/", "variant" => "invalid" }] }
        )
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /navigation\.cta\[0\]\.variant.*must be 'primary' or 'secondary'/m)
      end

      it "raises ConfigError for non-boolean external" do
        config = valid_config(
          "navigation" => { "cta" => [{ "text" => "CTA", "href" => "/", "external" => "yes" }] }
        )
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /navigation\.cta\[0\]\.external.*must be true or false/m)
      end

      it "raises ConfigError for more than 2 CTAs" do
        config = valid_config(
          "navigation" => {
            "cta" => [
              { "text" => "CTA 1", "href" => "/one" },
              { "text" => "CTA 2", "href" => "/two" },
              { "text" => "CTA 3", "href" => "/three" }
            ]
          }
        )
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /navigation\.cta.*maximum 2 CTAs allowed/m)
      end
    end
  end
end
