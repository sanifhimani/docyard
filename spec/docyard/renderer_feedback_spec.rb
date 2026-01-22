# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Renderer do
  let(:temp_dir) { Dir.mktmpdir }
  let(:docs_dir) { File.join(temp_dir, "docs") }

  before do
    FileUtils.mkdir_p(docs_dir)
    File.write(File.join(docs_dir, "index.md"), "# Welcome\n\nHello world")
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_config(feedback_config = {}, analytics_config = nil)
    config_content = {
      "title" => "Test Docs",
      "source" => "docs"
    }
    config_content["feedback"] = feedback_config if feedback_config.any?
    config_content["analytics"] = analytics_config || { "google" => "G-TESTID" } if feedback_config["enabled"] == true

    File.write(File.join(temp_dir, "docyard.yml"), config_content.to_yaml)
    Dir.chdir(temp_dir) { Docyard::Config.new }
  end

  def render_page(config)
    renderer = Docyard::Renderer.new(config: config)
    renderer.render_file(File.join(docs_dir, "index.md"))
  end

  describe "when feedback is disabled" do
    it "does not render the feedback widget", :aggregate_failures do
      config = create_config({ "enabled" => false })
      html = render_page(config)

      expect(html).not_to include('class="feedback"')
      expect(html).not_to include("Was this page helpful?")
    end

    it "does not render feedback by default" do
      config = create_config({})
      html = render_page(config)

      expect(html).not_to include('class="feedback"')
    end
  end

  describe "when feedback is enabled" do
    it "renders the feedback widget" do
      config = create_config({ "enabled" => true })
      html = render_page(config)

      expect(html).to include('class="feedback"')
    end

    it "renders the default question" do
      config = create_config({ "enabled" => true })
      html = render_page(config)

      expect(html).to include("Was this page helpful?")
    end

    it "renders custom question when configured", :aggregate_failures do
      config = create_config({ "enabled" => true, "question" => "Did this help?" })
      html = render_page(config)

      expect(html).to include("Did this help?")
      expect(html).not_to include("Was this page helpful?")
    end

    it "renders thumbs up and thumbs down buttons", :aggregate_failures do
      config = create_config({ "enabled" => true })
      html = render_page(config)

      expect(html).to include('data-feedback="yes"')
      expect(html).to include('data-feedback="no"')
    end

    it "renders accessible button labels", :aggregate_failures do
      config = create_config({ "enabled" => true })
      html = render_page(config)

      expect(html).to include('aria-label="Yes, this page was helpful"')
      expect(html).to include('aria-label="No, this page was not helpful"')
    end

    it "renders thanks message with aria-live", :aggregate_failures do
      config = create_config({ "enabled" => true })
      html = render_page(config)

      expect(html).to include('aria-live="polite"')
      expect(html).to include("Thanks for your feedback!")
    end

    it "renders phosphor thumbs icons", :aggregate_failures do
      config = create_config({ "enabled" => true })
      html = render_page(config)

      expect(html).to include("ph-thumbs-up")
      expect(html).to include("ph-thumbs-down")
    end

    it "excludes feedback from search indexing" do
      config = create_config({ "enabled" => true })
      html = render_page(config)

      expect(html).to include("data-pagefind-ignore")
    end
  end
end
