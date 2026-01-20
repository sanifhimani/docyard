# frozen_string_literal: true

RSpec.describe Docyard::Navigation::PageNavigationBuilder do
  include_context "with docs directory"

  let(:config) { Docyard::Config.load(temp_dir) }
  let(:builder) { described_class.new(docs_path: docs_dir, config: config) }

  describe "#build" do
    context "when show_sidebar is false" do
      let(:markdown) { Docyard::Markdown.new("# Test") }

      it "returns empty navigation" do
        result = builder.build(current_path: "/test", markdown: markdown, show_sidebar: false)

        expect(result).to eq({
                               sidebar_html: "",
                               prev_next_html: "",
                               breadcrumbs: nil
                             })
      end
    end

    context "when show_sidebar is true" do
      before do
        create_doc("getting-started.md", "---\ntitle: Getting Started\n---\nContent")
        create_doc("advanced.md", "---\ntitle: Advanced\n---\nContent")
        File.write(File.join(docs_dir, "_sidebar.yml"), <<~YAML)
          - getting-started
          - advanced
        YAML
      end

      let(:markdown) { Docyard::Markdown.new("---\ntitle: Getting Started\n---\nContent") }

      it "returns sidebar HTML", :aggregate_failures do
        result = builder.build(current_path: "/getting-started", markdown: markdown, show_sidebar: true)

        expect(result[:sidebar_html]).to include("<nav>")
        expect(result[:sidebar_html]).to include("Getting Started")
      end

      it "returns prev_next HTML" do
        result = builder.build(current_path: "/getting-started", markdown: markdown, show_sidebar: true)

        expect(result[:prev_next_html]).to include("Advanced")
      end

      it "returns breadcrumbs builder" do
        result = builder.build(current_path: "/getting-started", markdown: markdown, show_sidebar: true)

        expect(result[:breadcrumbs]).to be_a(Docyard::BreadcrumbBuilder)
      end
    end

    context "when breadcrumbs are disabled in config" do
      let(:config) do
        create_config(<<~YAML)
          navigation:
            breadcrumbs: false
        YAML
        Docyard::Config.load(temp_dir)
      end
      let(:markdown) { Docyard::Markdown.new("---\ntitle: Test\n---\nContent") }

      before do
        create_doc("test.md", "---\ntitle: Test\n---\nContent")
        File.write(File.join(docs_dir, "_sidebar.yml"), "- test")
      end

      it "returns nil breadcrumbs" do
        result = builder.build(current_path: "/test", markdown: markdown, show_sidebar: true)

        expect(result[:breadcrumbs]).to be_nil
      end
    end

    context "with header_ctas" do
      before do
        create_doc("test.md", "---\ntitle: Test\n---\nContent")
        File.write(File.join(docs_dir, "_sidebar.yml"), "- test")
      end

      let(:config) do
        create_config(<<~YAML)
          navigation:
            cta:
              - text: GitHub
                href: https://github.com
        YAML
        Docyard::Config.load(temp_dir)
      end

      let(:markdown) { Docyard::Markdown.new("---\ntitle: Test\n---\nContent") }
      let(:header_ctas) { [{ text: "GitHub", href: "https://github.com" }] }

      it "passes header_ctas to sidebar builder" do
        result = builder.build(
          current_path: "/test",
          markdown: markdown,
          header_ctas: header_ctas,
          show_sidebar: true
        )

        expect(result[:sidebar_html]).to include("<nav>")
      end
    end

    context "with sidebar_cache" do
      let(:cache) { Docyard::Sidebar::Cache.new(docs_path: docs_dir, config: config) }
      let(:markdown) { Docyard::Markdown.new("---\ntitle: Test\n---\nContent") }
      let(:builder) { described_class.new(docs_path: docs_dir, config: config, sidebar_cache: cache) }

      before do
        create_doc("test.md", "---\ntitle: Test\n---\nContent")
        File.write(File.join(docs_dir, "_sidebar.yml"), "- test")
        cache.build
      end

      it "uses cached sidebar data" do
        result = builder.build(current_path: "/test", markdown: markdown, show_sidebar: true)

        expect(result[:sidebar_html]).to include("Test")
      end
    end
  end
end
