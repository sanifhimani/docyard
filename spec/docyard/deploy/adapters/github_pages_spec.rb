# frozen_string_literal: true

require "docyard/deploy/adapters/github_pages"

RSpec.describe Docyard::Deploy::Adapters::GithubPages do
  let(:config) { instance_double(Docyard::Config, title: "My Docs") }
  let(:adapter) { described_class.new(output_dir: "dist", production: true, config: config) }
  let(:success_status) { instance_double(Process::Status, success?: true) }

  describe "#platform_name" do
    it "returns GitHub Pages" do
      expect(adapter.platform_name).to eq("GitHub Pages")
    end
  end

  describe "#deploy" do
    before do
      allow(Open3).to receive(:capture3).with("which", "gh")
        .and_return(["/usr/bin/gh\n", "", success_status])
      allow(Open3).to receive(:capture3).with("git", "remote", "get-url", "origin")
        .and_return(["git@github.com:user/my-docs.git\n", "", success_status])
      allow(FileUtils).to receive(:cp_r)
      allow(Open3).to receive(:capture3).with("git", "-C", anything, "init", "-b", "gh-pages")
        .and_return(["", "", success_status])
      allow(Open3).to receive(:capture3).with("git", "-C", anything, "add", ".")
        .and_return(["", "", success_status])
      allow(Open3).to receive(:capture3).with("git", "-C", anything, "commit", "-m", "Deploy via docyard")
        .and_return(["", "", success_status])
      allow(Open3).to receive(:capture3).with("git", "-C", anything, "remote", "add", "origin", anything)
        .and_return(["", "", success_status])
      allow(Open3).to receive(:capture3).with("git", "-C", anything, "push", "--force", "origin", "gh-pages")
        .and_return(["", "", success_status])
    end

    it "deploys to gh-pages branch and returns pages URL" do
      result = adapter.deploy
      expect(result).to eq("https://user.github.io/my-docs/")
    end

    context "with HTTPS remote URL" do
      before do
        allow(Open3).to receive(:capture3).with("git", "remote", "get-url", "origin")
          .and_return(["https://github.com/org/repo.git\n", "", success_status])
      end

      it "extracts the correct pages URL" do
        result = adapter.deploy
        expect(result).to eq("https://org.github.io/repo/")
      end
    end

    context "when gh CLI is not installed" do
      before do
        allow(Open3).to receive(:capture3).with("which", "gh")
          .and_return(["", "gh not found", instance_double(Process::Status, success?: false)])
      end

      it "raises DeployError with install hint" do
        expect { adapter.deploy }.to raise_error(Docyard::DeployError, %r{https://cli.github.com})
      end
    end

    context "when git push fails" do
      before do
        allow(Open3).to receive(:capture3).with("git", "-C", anything, "push", "--force", "origin", "gh-pages")
          .and_return(["", "Permission denied", instance_double(Process::Status, success?: false)])
      end

      it "raises DeployError" do
        expect { adapter.deploy }.to raise_error(Docyard::DeployError, /Permission denied/)
      end
    end
  end
end
