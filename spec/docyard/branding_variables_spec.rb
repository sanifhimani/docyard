# frozen_string_literal: true

RSpec.describe Docyard::BrandingVariables do
  let(:test_class) do
    Class.new do
      include Docyard::BrandingVariables

      def call_assign_branding_variables(branding, current_path = "/")
        assign_branding_variables(branding, current_path)
      end

      def call_tab_active?(tab_href, current_path)
        tab_active?(tab_href, current_path)
      end
    end
  end

  let(:instance) { test_class.new }

  describe "#assign_branding_variables" do
    it "assigns site branding defaults when empty", :aggregate_failures do
      instance.call_assign_branding_variables({})

      expect(instance.instance_variable_get(:@site_title)).to eq(Docyard::Constants::DEFAULT_SITE_TITLE)
      expect(instance.instance_variable_get(:@logo)).to eq(Docyard::Constants::DEFAULT_LOGO_PATH)
      expect(instance.instance_variable_get(:@favicon)).to eq(Docyard::Constants::DEFAULT_FAVICON_PATH)
    end

    it "assigns provided branding values", :aggregate_failures do
      branding = {
        site_title: "My Docs",
        logo: "/custom-logo.svg",
        favicon: "/custom-favicon.ico"
      }
      instance.call_assign_branding_variables(branding)

      expect(instance.instance_variable_get(:@site_title)).to eq("My Docs")
      expect(instance.instance_variable_get(:@logo)).to eq("/custom-logo.svg")
      expect(instance.instance_variable_get(:@favicon)).to eq("/custom-favicon.ico")
    end

    it "enables search by default" do
      instance.call_assign_branding_variables({})

      expect(instance.instance_variable_get(:@search_enabled)).to be true
    end

    it "disables search when explicitly set to false" do
      instance.call_assign_branding_variables({ search_enabled: false })

      expect(instance.instance_variable_get(:@search_enabled)).to be false
    end

    it "enables credits by default" do
      instance.call_assign_branding_variables({})

      expect(instance.instance_variable_get(:@credits)).to be true
    end

    it "disables credits when set to false" do
      instance.call_assign_branding_variables({ credits: false })

      expect(instance.instance_variable_get(:@credits)).to be false
    end

    it "marks tabs as active based on current path", :aggregate_failures do
      branding = {
        tabs: [
          { text: "Guide", href: "/guide" },
          { text: "API", href: "/api" }
        ]
      }
      instance.call_assign_branding_variables(branding, "/guide/intro")

      tabs = instance.instance_variable_get(:@tabs)
      expect(tabs[0][:active]).to be true
      expect(tabs[1][:active]).to be false
    end
  end

  describe "#tab_active?" do
    it "returns true for exact path match" do
      expect(instance.call_tab_active?("/guide", "/guide")).to be true
    end

    it "returns true for nested path under tab" do
      expect(instance.call_tab_active?("/guide", "/guide/setup")).to be true
    end

    it "returns false for unrelated paths" do
      expect(instance.call_tab_active?("/guide", "/api")).to be false
    end

    it "returns false for external URLs" do
      expect(instance.call_tab_active?("https://github.com", "/")).to be false
    end

    it "handles trailing slashes correctly", :aggregate_failures do
      expect(instance.call_tab_active?("/guide/", "/guide")).to be true
      expect(instance.call_tab_active?("/guide", "/guide/")).to be true
    end

    it "returns false when tab_href is nil" do
      expect(instance.call_tab_active?(nil, "/guide")).to be false
    end

    it "returns false when current_path is nil" do
      expect(instance.call_tab_active?("/guide", nil)).to be false
    end
  end
end
