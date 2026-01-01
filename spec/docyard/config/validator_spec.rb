# frozen_string_literal: true

RSpec.describe Docyard::Config::Validator do
  include_context "with temp directory"

  let(:base_config) do
    {
      "site" => { "title" => "Documentation", "description" => "" },
      "branding" => {
        "logo" => nil, "logo_dark" => nil, "favicon" => nil,
        "appearance" => { "logo" => true, "title" => true }
      },
      "build" => { "output_dir" => "dist", "base_url" => "/", "clean" => true },
      "markdown" => { "lineNumbers" => false }
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
          "site" => { "title" => "My Docs", "description" => "Documentation" },
          "build" => { "output_dir" => "public", "base_url" => "/docs/" }
        )
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end

      it "does not raise for valid boolean values" do
        config = valid_config(
          "build" => { "clean" => false },
          "markdown" => { "lineNumbers" => true }
        )
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end
    end

    context "with invalid site section" do
      it "raises ConfigError for non-string title" do
        config = valid_config("site" => { "title" => 123 })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /site\.title.*must be a string/m)
      end

      it "raises ConfigError for non-string description" do
        config = valid_config("site" => { "description" => ["array"] })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /site\.description.*must be a string/m)
      end
    end

    context "with invalid build section" do
      it "raises ConfigError for non-string output_dir" do
        config = valid_config("build" => { "output_dir" => 123 })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /build\.output_dir.*must be a string/m)
      end

      it "raises ConfigError for output_dir with forward slash" do
        config = valid_config("build" => { "output_dir" => "dist/folder" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /build\.output_dir.*cannot contain slashes/m)
      end

      it "raises ConfigError for output_dir with backslash" do
        config = valid_config("build" => { "output_dir" => 'dist\folder' })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /build\.output_dir.*cannot contain slashes/m)
      end

      it "raises ConfigError for base_url not starting with slash" do
        config = valid_config("build" => { "base_url" => "docs/" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /build\.base_url.*must start with/m)
      end

      it "raises ConfigError for non-boolean clean" do
        config = valid_config("build" => { "clean" => "yes" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /build\.clean.*must be true or false/m)
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

      it "raises ConfigError for non-boolean appearance.logo" do
        config = valid_config("branding" => { "appearance" => { "logo" => "yes" } })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /branding\.appearance\.logo.*must be true or false/m)
      end

      it "raises ConfigError for non-boolean appearance.title" do
        config = valid_config("branding" => { "appearance" => { "title" => 1 } })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /branding\.appearance\.title.*must be true or false/m)
      end
    end

    context "with invalid markdown section" do
      it "raises ConfigError for non-boolean lineNumbers" do
        config = valid_config("markdown" => { "lineNumbers" => "yes" })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError, /markdown\.lineNumbers.*must be true or false/m)
      end

      it "does not validate lineNumbers when key is absent" do
        config = valid_config
        config["markdown"] = {}
        validator = described_class.new(config)

        expect { validator.validate! }.not_to raise_error
      end
    end

    context "with multiple errors" do
      it "reports all validation errors", :aggregate_failures do
        config = valid_config(
          "site" => { "title" => 123 },
          "build" => { "clean" => "yes", "base_url" => "no-slash" }
        )
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError) do |error|
            expect(error.message).to include("site.title")
            expect(error.message).to include("build.clean")
            expect(error.message).to include("build.base_url")
          end
      end

      it "formats error messages with field, error, got, and fix", :aggregate_failures do
        config = valid_config("site" => { "title" => 123 })
        validator = described_class.new(config)

        expect { validator.validate! }
          .to raise_error(Docyard::ConfigError) do |error|
            expect(error.message).to include("Field: site.title")
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
  end
end
