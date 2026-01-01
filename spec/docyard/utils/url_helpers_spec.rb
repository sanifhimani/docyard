# frozen_string_literal: true

RSpec.describe Docyard::Utils::UrlHelpers do
  let(:test_class) do
    Class.new do
      include Docyard::Utils::UrlHelpers

      attr_accessor :base_url
    end
  end

  let(:helper) { test_class.new.tap { |h| h.base_url = "/" } }

  describe "#normalize_base_url" do
    it "returns / for nil" do
      expect(helper.normalize_base_url(nil)).to eq("/")
    end

    it "returns / for empty string" do
      expect(helper.normalize_base_url("")).to eq("/")
    end

    it "adds leading slash if missing" do
      expect(helper.normalize_base_url("docs")).to eq("/docs/")
    end

    it "adds trailing slash if missing" do
      expect(helper.normalize_base_url("/docs")).to eq("/docs/")
    end

    it "preserves existing slashes" do
      expect(helper.normalize_base_url("/docs/")).to eq("/docs/")
    end
  end

  describe "#link_path" do
    before { helper.base_url = "/docs/" }

    it "returns path unchanged for nil" do
      expect(helper.link_path(nil)).to be_nil
    end

    it "returns http URLs unchanged" do
      expect(helper.link_path("http://example.com")).to eq("http://example.com")
    end

    it "returns https URLs unchanged" do
      expect(helper.link_path("https://example.com")).to eq("https://example.com")
    end

    it "prepends base_url to relative paths" do
      expect(helper.link_path("/page")).to eq("/docs/page")
    end

    it "handles base_url without trailing slash" do
      helper.base_url = "/docs/"
      expect(helper.link_path("/page")).to eq("/docs/page")
    end
  end
end
