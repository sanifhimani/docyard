# frozen_string_literal: true

require "docyard/deploy/deployer"

RSpec.describe Docyard::Deploy::Deployer do
  let(:config) { instance_double(Docyard::Config, title: "My Docs", build: build_config) }
  let(:build_config) { Docyard::Config::Section.new("output" => "dist") }

  before do
    allow(Docyard::Config).to receive(:new).and_return(config)
  end

  describe "#deploy" do
    context "when platform is specified and build is skipped" do
      let(:deployer) { described_class.new(to: "vercel", production: true, skip_build: true) }
      let(:adapter) { instance_double(Docyard::Deploy::Adapters::Vercel, platform_name: "Vercel") }

      before do
        allow(Docyard::Deploy::Adapters::Vercel).to receive(:new).and_return(adapter)
        allow(adapter).to receive(:deploy).and_return("https://my-docs.vercel.app")
      end

      it "deploys successfully and returns true" do
        expect { deployer.deploy }.to output(/Deployed successfully/).to_stdout
      end

      it "prints the deploy URL" do
        expect { deployer.deploy }.to output(%r{https://my-docs.vercel.app}).to_stdout
      end

      it "returns true" do
        allow($stdout).to receive(:write)
        expect(deployer.deploy).to be true
      end

      it "does not run a build" do
        allow($stdout).to receive(:write)
        deployer.deploy
        expect(Docyard::Deploy::Adapters::Vercel).to have_received(:new)
          .with(output_dir: "dist", production: true, config: config)
      end
    end

    context "when platform is auto-detected" do
      let(:deployer) { described_class.new(production: true, skip_build: true) }
      let(:adapter) { instance_double(Docyard::Deploy::Adapters::Netlify, platform_name: "Netlify") }
      let(:platform_detector) { instance_double(Docyard::Deploy::PlatformDetector, detect: "netlify") }

      before do
        allow(Docyard::Deploy::PlatformDetector).to receive(:new).and_return(platform_detector)
        allow(Docyard::Deploy::Adapters::Netlify).to receive(:new).and_return(adapter)
        allow(adapter).to receive(:deploy).and_return("https://my-docs.netlify.app")
      end

      it "uses the detected platform" do
        expect { deployer.deploy }.to output(/Netlify/).to_stdout
      end
    end

    context "when no platform is detected" do
      let(:deployer) { described_class.new(skip_build: true) }
      let(:platform_detector) { instance_double(Docyard::Deploy::PlatformDetector, detect: nil) }

      before do
        allow(Docyard::Deploy::PlatformDetector).to receive(:new).and_return(platform_detector)
      end

      it "prints error and returns false" do
        expect { deployer.deploy }.to output(/Could not detect platform/).to_stdout
      end

      it "returns false" do
        allow($stdout).to receive(:write)
        expect(deployer.deploy).to be false
      end
    end

    context "when an unknown platform is specified" do
      let(:deployer) { described_class.new(to: "heroku", skip_build: true) }

      it "prints error and returns false" do
        expect { deployer.deploy }.to output(/Unknown platform: heroku/).to_stdout
      end
    end

    context "when deploy fails" do
      let(:deployer) { described_class.new(to: "vercel", skip_build: true) }
      let(:adapter) { instance_double(Docyard::Deploy::Adapters::Vercel, platform_name: "Vercel") }

      before do
        allow(Docyard::Deploy::Adapters::Vercel).to receive(:new).and_return(adapter)
        allow(adapter).to receive(:deploy).and_raise(Docyard::DeployError, "Not authenticated")
      end

      it "prints the error message and returns false" do
        expect { deployer.deploy }.to output(/Deploy failed/).to_stdout
      end

      it "returns false" do
        allow($stdout).to receive(:write)
        expect(deployer.deploy).to be false
      end
    end

    context "when build is not skipped" do
      let(:deployer) { described_class.new(to: "vercel", production: true, skip_build: false) }
      let(:builder) { instance_double(Docyard::Builder, build: true) }
      let(:adapter) { instance_double(Docyard::Deploy::Adapters::Vercel, platform_name: "Vercel") }

      before do
        allow(Docyard::Builder).to receive(:new).and_return(builder)
        allow(Docyard::Deploy::Adapters::Vercel).to receive(:new).and_return(adapter)
        allow(adapter).to receive(:deploy).and_return("https://my-docs.vercel.app")
      end

      it "runs the build before deploying" do
        allow($stdout).to receive(:write)
        deployer.deploy
        expect(builder).to have_received(:build)
      end
    end

    context "when build fails" do
      let(:deployer) { described_class.new(to: "vercel", skip_build: false) }
      let(:builder) { instance_double(Docyard::Builder, build: false) }

      before do
        allow(Docyard::Builder).to receive(:new).and_return(builder)
      end

      it "returns false without deploying" do
        expect { deployer.deploy }.to output(/Deploy failed/).to_stdout
      end
    end

    context "with preview environment" do
      let(:deployer) { described_class.new(to: "vercel", production: false, skip_build: true) }
      let(:adapter) { instance_double(Docyard::Deploy::Adapters::Vercel, platform_name: "Vercel") }

      before do
        allow(Docyard::Deploy::Adapters::Vercel).to receive(:new).and_return(adapter)
        allow(adapter).to receive(:deploy).and_return("https://preview.vercel.app")
      end

      it "prints preview environment" do
        expect { deployer.deploy }.to output(/preview/).to_stdout
      end
    end
  end
end
