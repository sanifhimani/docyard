# frozen_string_literal: true

RSpec.describe Docyard::OgHelpers do
  let(:test_class) do
    Class.new do
      include Docyard::OgHelpers

      attr_accessor :site_description
    end
  end

  let(:instance) { test_class.new }

  describe "#assign_og_variables" do
    context "when site_url is configured" do
      let(:branding) { { site_url: "https://example.com" } }

      it "enables OG tags" do
        instance.assign_og_variables(branding, nil, nil, "/")

        expect(instance.instance_variable_get(:@og_enabled)).to be true
      end

      it "builds canonical URL from site_url and current_path" do
        instance.assign_og_variables(branding, nil, nil, "/guide/intro")

        expect(instance.instance_variable_get(:@og_url)).to eq("https://example.com/guide/intro")
      end

      it "handles site_url with trailing slash" do
        branding_with_slash = { site_url: "https://example.com/" }

        instance.assign_og_variables(branding_with_slash, nil, nil, "/guide")

        expect(instance.instance_variable_get(:@og_url)).to eq("https://example.com/guide")
      end

      it "handles current_path without leading slash" do
        instance.assign_og_variables(branding, nil, nil, "guide")

        expect(instance.instance_variable_get(:@og_url)).to eq("https://example.com/guide")
      end
    end

    context "when site_url is not configured" do
      it "disables OG tags when site_url is nil" do
        instance.assign_og_variables({ site_url: nil }, nil, nil, "/")

        expect(instance.instance_variable_get(:@og_enabled)).to be false
      end

      it "disables OG tags when site_url is empty" do
        instance.assign_og_variables({ site_url: "" }, nil, nil, "/")

        expect(instance.instance_variable_get(:@og_enabled)).to be false
      end
    end

    context "with descriptions" do
      let(:branding) { { site_url: "https://example.com" } }

      it "uses page description when provided" do
        instance.assign_og_variables(branding, "Page description", nil, "/")

        expect(instance.instance_variable_get(:@og_description)).to eq("Page description")
      end

      it "falls back to site description when page description is nil" do
        instance.site_description = "Site description"

        instance.assign_og_variables(branding, nil, nil, "/")

        expect(instance.instance_variable_get(:@og_description)).to eq("Site description")
      end
    end

    context "with OG images" do
      let(:branding) { { site_url: "https://example.com", og_image: "/images/og.png" } }

      it "builds absolute URL for relative image path" do
        instance.assign_og_variables(branding, nil, nil, "/")

        expect(instance.instance_variable_get(:@og_image)).to eq("https://example.com/images/og.png")
      end

      it "uses page og_image over site og_image" do
        instance.assign_og_variables(branding, nil, "/images/page-og.png", "/")

        expect(instance.instance_variable_get(:@og_image)).to eq("https://example.com/images/page-og.png")
      end

      it "preserves absolute image URLs" do
        instance.assign_og_variables(branding, nil, "https://cdn.example.com/og.png", "/")

        expect(instance.instance_variable_get(:@og_image)).to eq("https://cdn.example.com/og.png")
      end

      it "handles image path without leading slash" do
        instance.assign_og_variables(branding, nil, "images/og.png", "/")

        expect(instance.instance_variable_get(:@og_image)).to eq("https://example.com/images/og.png")
      end

      it "returns nil when no og_image is configured" do
        branding_no_image = { site_url: "https://example.com" }

        instance.assign_og_variables(branding_no_image, nil, nil, "/")

        expect(instance.instance_variable_get(:@og_image)).to be_nil
      end
    end

    context "with Twitter handle" do
      let(:branding) { { site_url: "https://example.com", twitter: "@docyard" } }

      it "assigns twitter handle" do
        instance.assign_og_variables(branding, nil, nil, "/")

        expect(instance.instance_variable_get(:@og_twitter)).to eq("@docyard")
      end
    end
  end
end
