# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Docyard::Sidebar::ConfigParser do
  let(:temp_dir) { Dir.mktmpdir }
  let(:docs_path) { File.join(temp_dir, "docs") }
  let(:current_path) { "/" }

  before { FileUtils.mkdir_p(docs_path) }
  after { FileUtils.rm_rf(temp_dir) }

  def create_file(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  describe "#parse" do
    context "with simple slug strings" do
      it "resolves file items from slugs", :aggregate_failures do
        create_file("introduction.md", "---\ntitle: Introduction\n---\n# Intro")
        config_items = ["introduction"]

        parser = described_class.new(config_items, docs_path: docs_path, current_path: current_path)
        items = parser.parse

        expect(items.size).to eq(1)
        expect(items.first.slug).to eq("introduction")
        expect(items.first.text).to eq("Introduction")
        expect(items.first.path).to eq("/introduction")
        expect(items.first.type).to eq(:file)
      end

      it "titleizes slug when file doesn't exist" do
        config_items = ["quick-start"]

        parser = described_class.new(config_items, docs_path: docs_path, current_path: current_path)
        items = parser.parse

        expect(items.first.text).to eq("Quick Start")
      end
    end

    context "with hash configuration" do
      before { create_file("intro.md", "# Introduction") }

      it "parses item with custom text" do
        config_items = [{ "intro" => { "text" => "Getting Started" } }]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.text).to eq("Getting Started")
      end

      it "parses item with icon" do
        config_items = [{ "intro" => { "icon" => "rocket-launch" } }]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.icon).to eq("rocket-launch")
      end

      it "parses item with text and icon", :aggregate_failures do
        config_items = [{ "intro" => { "text" => "Quick Start", "icon" => "lightning" } }]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.text).to eq("Quick Start")
        expect(items.first.icon).to eq("lightning")
      end

      it "parses item with custom link" do
        config_items = [{ "intro" => { "link" => "/custom/path" } }]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.path).to eq("/custom/path")
      end
    end

    context "with external links" do
      it "parses external link with text", :aggregate_failures do
        config_items = [{
          "text" => "GitHub",
          "link" => "https://github.com/user/repo"
        }]

        parser = described_class.new(config_items, docs_path: docs_path, current_path: current_path)
        items = parser.parse

        expect(items.first.text).to eq("GitHub")
        expect(items.first.path).to eq("https://github.com/user/repo")
        expect(items.first.target).to eq("_blank")
        expect(items.first.external?).to be true
      end

      it "parses external link with icon" do
        config_items = [{
          "text" => "GitHub",
          "link" => "https://github.com/user/repo",
          "icon" => "github"
        }]

        parser = described_class.new(config_items, docs_path: docs_path, current_path: current_path)
        items = parser.parse

        expect(items.first.icon).to eq("github")
      end

      it "allows custom target override" do
        config_items = [{
          "text" => "Link",
          "link" => "https://example.com",
          "target" => "_self"
        }]

        parser = described_class.new(config_items, docs_path: docs_path, current_path: current_path)
        items = parser.parse

        expect(items.first.target).to eq("_self")
      end
    end

    context "with nested groups" do
      it "parses directory with child items", :aggregate_failures do
        create_file("getting-started/intro.md", "# Introduction")
        create_file("getting-started/setup.md", "# Setup")
        config_items = [{ "getting-started" => { "items" => %w[intro setup] } }]

        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.slug).to eq("getting-started")
        expect(items.first.type).to eq(:directory)
        expect(items.first.children.size).to eq(2)
      end

      it "parses collapsed groups" do
        create_file("advanced/topic.md", "# Topic")
        config_items = [{ "advanced" => { "collapsed" => true, "items" => ["topic"] } }]

        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.collapsed).to be true
      end

      it "parses group with custom text" do
        create_file("guides/intro.md", "# Introduction")
        config_items = [{ "guides" => { "text" => "User Guides", "items" => ["intro"] } }]

        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.text).to eq("User Guides")
      end

      it "parses group with custom icon" do
        create_file("guides/intro.md", "# Introduction")
        config_items = [{ "guides" => { "icon" => "lightbulb", "items" => ["intro"] } }]

        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.icon).to eq("lightbulb")
      end

      it "parses deeply nested groups" do
        create_file("a/b/c.md", "# Content")
        config_items = [{ "a" => { "items" => [{ "b" => { "items" => ["c"] } }] } }]

        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.children.first.children.first.slug).to eq("c")
      end
    end

    context "with frontmatter metadata" do
      it "uses sidebar.icon from frontmatter" do
        create_file("intro.md", "---\ntitle: Introduction\nsidebar:\n  icon: rocket-launch\n---\n# Content")
        items = described_class.new(["intro"], docs_path: docs_path, current_path: current_path).parse

        expect(items.first.icon).to eq("rocket-launch")
      end

      it "uses sidebar.text from frontmatter" do
        create_file("intro.md", "---\ntitle: Introduction\nsidebar:\n  text: Quick Intro\n---\n# Content")
        items = described_class.new(["intro"], docs_path: docs_path, current_path: current_path).parse

        expect(items.first.text).to eq("Quick Intro")
      end

      it "prioritizes config text over frontmatter" do
        create_file("intro.md", "---\ntitle: Introduction\nsidebar:\n  text: From Frontmatter\n---")
        config_items = [{ "intro" => { "text" => "From Config" } }]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.text).to eq("From Config")
      end

      it "prioritizes config icon over frontmatter" do
        create_file("intro.md", "---\ntitle: Introduction\nsidebar:\n  icon: rocket-launch\n---")
        config_items = [{ "intro" => { "icon" => "star" } }]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.icon).to eq("star")
      end

      it "falls back to title when sidebar.text not present" do
        create_file("intro.md", "---\ntitle: Introduction Page\n---\n# Content")
        items = described_class.new(["intro"], docs_path: docs_path, current_path: current_path).parse

        expect(items.first.text).to eq("Introduction Page")
      end
    end

    context "with active path detection" do
      it "marks item as active when path matches" do
        create_file("intro.md", "# Introduction")
        config_items = ["intro"]

        parser = described_class.new(config_items, docs_path: docs_path, current_path: "/intro")
        items = parser.parse

        expect(items.first.active).to be true
      end

      it "marks item as inactive when path doesn't match" do
        create_file("intro.md", "# Introduction")
        config_items = ["intro"]

        parser = described_class.new(config_items, docs_path: docs_path, current_path: "/other")
        items = parser.parse

        expect(items.first.active).to be false
      end
    end

    context "with nil handling" do
      it "handles nil options gracefully", :aggregate_failures do
        create_file("intro.md", "# Introduction")
        config_items = [{ "intro" => nil }]

        parser = described_class.new(config_items, docs_path: docs_path, current_path: current_path)

        expect { parser.parse }.not_to raise_error
        items = parser.parse
        expect(items.first.slug).to eq("intro")
      end

      it "handles empty config items" do
        parser = described_class.new([], docs_path: docs_path, current_path: current_path)
        items = parser.parse

        expect(items).to be_empty
      end

      it "handles nil config items" do
        parser = described_class.new(nil, docs_path: docs_path, current_path: current_path)
        items = parser.parse

        expect(items).to be_empty
      end
    end

    context "with mixed configuration" do
      before do
        create_file("intro.md", "# Introduction")
        create_file("setup.md", "# Setup")
        create_file("advanced/topic.md", "# Topic")
      end

      it "parses simple slug strings" do
        config_items = ["intro"]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.slug).to eq("intro")
      end

      it "parses hash items with options" do
        config_items = [{ "setup" => { "icon" => "package" } }]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.icon).to eq("package")
      end

      it "parses nested directory items" do
        config_items = [{ "advanced" => { "text" => "Advanced Topics", "collapsed" => true, "items" => ["topic"] } }]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.collapsed).to be true
      end

      it "parses external links" do
        config_items = [{ "text" => "GitHub", "link" => "https://github.com", "icon" => "github" }]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.first.external?).to be true
      end

      it "parses all configuration types together" do
        config_items = [
          "intro",
          { "setup" => { "icon" => "package" } },
          { "advanced" => { "collapsed" => true, "items" => ["topic"] } },
          { "text" => "GitHub", "link" => "https://github.com" }
        ]
        items = described_class.new(config_items, docs_path: docs_path, current_path: current_path).parse

        expect(items.size).to eq(4)
      end
    end
  end
end
