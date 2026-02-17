# frozen_string_literal: true

require "docyard/deploy/platform_detector"

RSpec.describe Docyard::Deploy::PlatformDetector do
  subject(:detector) { described_class.new(project_root) }

  let(:project_root) { Dir.mktmpdir }

  after { FileUtils.remove_entry(project_root) }

  describe "#detect" do
    context "when vercel.json exists" do
      before { FileUtils.touch(File.join(project_root, "vercel.json")) }

      it "returns vercel" do
        expect(detector.detect).to eq("vercel")
      end
    end

    context "when .vercel directory exists" do
      before { FileUtils.mkdir_p(File.join(project_root, ".vercel")) }

      it "returns vercel" do
        expect(detector.detect).to eq("vercel")
      end
    end

    context "when netlify.toml exists" do
      before { FileUtils.touch(File.join(project_root, "netlify.toml")) }

      it "returns netlify" do
        expect(detector.detect).to eq("netlify")
      end
    end

    context "when .netlify directory exists" do
      before { FileUtils.mkdir_p(File.join(project_root, ".netlify")) }

      it "returns netlify" do
        expect(detector.detect).to eq("netlify")
      end
    end

    context "when wrangler.toml exists" do
      before { FileUtils.touch(File.join(project_root, "wrangler.toml")) }

      it "returns cloudflare" do
        expect(detector.detect).to eq("cloudflare")
      end
    end

    context "when wrangler.jsonc exists" do
      before { FileUtils.touch(File.join(project_root, "wrangler.jsonc")) }

      it "returns cloudflare" do
        expect(detector.detect).to eq("cloudflare")
      end
    end

    context "when .github/workflows directory exists" do
      before { FileUtils.mkdir_p(File.join(project_root, ".github/workflows")) }

      it "returns github-pages" do
        expect(detector.detect).to eq("github-pages")
      end
    end

    context "when no platform files exist" do
      it "returns nil" do
        expect(detector.detect).to be_nil
      end
    end

    context "when multiple platform files exist" do
      before do
        FileUtils.touch(File.join(project_root, "vercel.json"))
        FileUtils.touch(File.join(project_root, "netlify.toml"))
      end

      it "returns the highest priority platform" do
        expect(detector.detect).to eq("vercel")
      end
    end
  end
end
