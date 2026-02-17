# frozen_string_literal: true

require "docyard/deploy/adapters/vercel"

RSpec.describe Docyard::Deploy::Adapters::Vercel do
  let(:config) { instance_double(Docyard::Config, title: "My Docs") }
  let(:adapter) { described_class.new(output_dir: "dist", production: production, config: config) }
  let(:production) { true }

  describe "#platform_name" do
    it "returns Vercel" do
      expect(adapter.platform_name).to eq("Vercel")
    end
  end

  describe "#deploy" do
    before do
      allow(Open3).to receive(:capture3).with("which", "vercel")
        .and_return(["/usr/bin/vercel\n", "", instance_double(Process::Status, success?: true)])
    end

    context "when deploying to production" do
      it "runs vercel with --prod flag" do
        allow(Open3).to receive(:capture3).with("vercel", "dist", "--yes", "--prod")
          .and_return(["https://my-docs.vercel.app\n", "", instance_double(Process::Status, success?: true)])

        result = adapter.deploy
        expect(result).to eq("https://my-docs.vercel.app")
      end
    end

    context "when deploying preview" do
      let(:production) { false }

      it "runs vercel without --prod flag" do
        allow(Open3).to receive(:capture3).with("vercel", "dist", "--yes")
          .and_return(["https://my-docs-abc123.vercel.app\n", "", instance_double(Process::Status, success?: true)])

        result = adapter.deploy
        expect(result).to eq("https://my-docs-abc123.vercel.app")
      end
    end

    context "when vercel CLI is not installed" do
      before do
        allow(Open3).to receive(:capture3).with("which", "vercel")
          .and_return(["", "vercel not found", instance_double(Process::Status, success?: false)])
      end

      it "raises DeployError with install hint" do
        expect { adapter.deploy }.to raise_error(Docyard::DeployError, /npm i -g vercel/)
      end
    end

    context "when deploy command fails" do
      it "raises DeployError with error message" do
        allow(Open3).to receive(:capture3).with("vercel", "dist", "--yes", "--prod")
          .and_return(["", "Error: not authenticated", instance_double(Process::Status, success?: false)])

        expect { adapter.deploy }.to raise_error(Docyard::DeployError, /not authenticated/)
      end
    end
  end
end
