# frozen_string_literal: true

require "docyard/deploy/adapters/netlify"

RSpec.describe Docyard::Deploy::Adapters::Netlify do
  let(:config) { instance_double(Docyard::Config, title: "My Docs") }
  let(:adapter) { described_class.new(output_dir: "dist", production: production, config: config) }
  let(:production) { true }

  describe "#platform_name" do
    it "returns Netlify" do
      expect(adapter.platform_name).to eq("Netlify")
    end
  end

  describe "#deploy" do
    before do
      allow(Open3).to receive(:capture3).with("which", "netlify")
        .and_return(["/usr/bin/netlify\n", "", instance_double(Process::Status, success?: true)])
    end

    context "when deploying to production" do
      let(:netlify_output) do
        <<~OUTPUT
          Deploying to main site URL...
          Website URL: https://my-docs.netlify.app
        OUTPUT
      end

      it "runs netlify deploy with --prod flag and extracts URL" do
        allow(Open3).to receive(:capture3).with("netlify", "deploy", "--dir=dist", "--prod")
          .and_return([netlify_output, "", instance_double(Process::Status, success?: true)])

        result = adapter.deploy
        expect(result).to eq("https://my-docs.netlify.app")
      end
    end

    context "when deploying preview" do
      let(:production) { false }

      let(:netlify_output) do
        <<~OUTPUT
          Deploying to draft URL...
          Website draft URL: https://abc123--my-docs.netlify.app
        OUTPUT
      end

      it "runs netlify deploy without --prod and extracts draft URL" do
        allow(Open3).to receive(:capture3).with("netlify", "deploy", "--dir=dist")
          .and_return([netlify_output, "", instance_double(Process::Status, success?: true)])

        result = adapter.deploy
        expect(result).to eq("https://abc123--my-docs.netlify.app")
      end
    end

    context "when netlify CLI is not installed" do
      before do
        allow(Open3).to receive(:capture3).with("which", "netlify")
          .and_return(["", "netlify not found", instance_double(Process::Status, success?: false)])
      end

      it "raises DeployError with install hint" do
        expect { adapter.deploy }.to raise_error(Docyard::DeployError, /npm i -g netlify-cli/)
      end
    end
  end
end
