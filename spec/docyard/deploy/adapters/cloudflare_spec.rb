# frozen_string_literal: true

require "docyard/deploy/adapters/cloudflare"

RSpec.describe Docyard::Deploy::Adapters::Cloudflare do
  let(:config) { instance_double(Docyard::Config, title: "My Docs") }
  let(:adapter) { described_class.new(output_dir: "dist", production: true, config: config) }

  describe "#platform_name" do
    it "returns Cloudflare Pages" do
      expect(adapter.platform_name).to eq("Cloudflare Pages")
    end
  end

  describe "#deploy" do
    before do
      allow(Open3).to receive(:capture3).with("which", "wrangler")
        .and_return(["/usr/bin/wrangler\n", "", instance_double(Process::Status, success?: true)])
    end

    context "when deploy succeeds" do
      let(:wrangler_output) do
        "Deploying to https://my-docs.pages.dev\nSuccess!"
      end

      it "runs wrangler pages deploy with project name derived from title" do
        allow(Open3).to receive(:capture3)
          .with("wrangler", "pages", "deploy", "dist", "--project-name=my-docs")
          .and_return([wrangler_output, "", instance_double(Process::Status, success?: true)])

        result = adapter.deploy
        expect(result).to eq("https://my-docs.pages.dev")
      end
    end

    context "with a title containing special characters" do
      let(:config) { instance_double(Docyard::Config, title: "My Awesome Docs!") }

      it "sanitizes the project name" do
        allow(Open3).to receive(:capture3)
          .with("wrangler", "pages", "deploy", "dist", "--project-name=my-awesome-docs")
          .and_return(["https://my-awesome-docs.pages.dev\n", "", instance_double(Process::Status, success?: true)])

        result = adapter.deploy
        expect(result).to eq("https://my-awesome-docs.pages.dev")
      end
    end

    context "when wrangler CLI is not installed" do
      before do
        allow(Open3).to receive(:capture3).with("which", "wrangler")
          .and_return(["", "wrangler not found", instance_double(Process::Status, success?: false)])
      end

      it "raises DeployError with install hint" do
        expect { adapter.deploy }.to raise_error(Docyard::DeployError, /npm i -g wrangler/)
      end
    end
  end
end
