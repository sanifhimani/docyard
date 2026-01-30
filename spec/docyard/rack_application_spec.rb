# frozen_string_literal: true

RSpec.describe Docyard::RackApplication do
  let(:docs_path) { File.expand_path("spec/fixtures") }
  let(:app) { described_class.new(docs_path: docs_path) }

  describe "#call" do
    context "with documentation request" do
      it "returns 200 and renders file when found", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

        status, headers, body = app.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("Welcome to Docyard")
      end

      it "returns 404 when file not found", :aggregate_failures do
        env = { "PATH_INFO" => "/nonexistent", "QUERY_STRING" => "" }

        status, headers, body = app.call(env)

        expect(status).to eq(404)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("404 - Page Not Found")
      end

      it "uses default site title when no config provided", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

        _status, _headers, body = app.call(env)

        expect(body.first).to include("<title>")
        expect(body.first).to include("Documentation")
      end

      it "includes sidebar with navigation links", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

        _status, _headers, body = app.call(env)

        expect(body.first).to include("sidebar")
        expect(body.first).to include('href="/"')
      end

      it "includes prev/next navigation when multiple pages exist", :aggregate_failures do
        Dir.mktmpdir do |temp_dir|
          File.write(File.join(temp_dir, "docyard.yml"), "sidebar: auto")
          File.write(File.join(temp_dir, "index.md"), "---\ntitle: Home\n---\n# Home")
          File.write(File.join(temp_dir, "intro.md"), "---\ntitle: Introduction\n---\n# Intro")
          File.write(File.join(temp_dir, "guide.md"), "---\ntitle: Guide\n---\n# Guide")

          config = Docyard::Config.load(temp_dir)
          temp_app = described_class.new(docs_path: temp_dir, config: config)
          env = { "PATH_INFO" => "/intro", "QUERY_STRING" => "" }

          _status, _headers, body = temp_app.call(env)

          expect(body.first).to include("pager")
          expect(body.first).to include("Previous")
          expect(body.first).to include('href="/guide"')
        end
      end

      it "marks current page as active in sidebar", :aggregate_failures do
        Dir.mktmpdir do |temp_dir|
          File.write(File.join(temp_dir, "docyard.yml"), "sidebar: auto")
          File.write(File.join(temp_dir, "index.md"), "---\ntitle: Home\n---\n# Home")
          File.write(File.join(temp_dir, "intro.md"), "---\ntitle: Introduction\n---\n# Intro")
          File.write(File.join(temp_dir, "guide.md"), "---\ntitle: Guide\n---\n# Guide")

          config = Docyard::Config.load(temp_dir)
          temp_app = described_class.new(docs_path: temp_dir, config: config)
          env = { "PATH_INFO" => "/guide", "QUERY_STRING" => "" }

          _status, _headers, body = temp_app.call(env)

          expect(body.first).to match(%r{href="/guide"[^>]*class="[^"]*active})
        end
      end

      it "uses config site title when provided" do
        Dir.mktmpdir do |temp_dir|
          File.write(File.join(temp_dir, "docyard.yml"), "title: 'Custom Docs'")
          config = Docyard::Config.load(temp_dir)

          app_with_config = described_class.new(docs_path: docs_path, config: config)
          env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

          _status, _headers, body = app_with_config.call(env)

          expect(body.first).to include("Custom Docs")
        end
      end

      it "renders with logo when provided in config", :aggregate_failures do
        Dir.mktmpdir do |temp_dir|
          logo_path = File.join(temp_dir, "logo.svg")
          File.write(logo_path, "<svg></svg>")
          File.write(File.join(temp_dir, "docyard.yml"), "branding:\n  logo: '#{logo_path}'")
          config = Docyard::Config.load(temp_dir)
          app_with_config = described_class.new(docs_path: docs_path, config: config)

          _status, _headers, body = app_with_config.call({ "PATH_INFO" => "/", "QUERY_STRING" => "" })

          expect(body.first).to include("src=\"/#{logo_path}\"")
          expect(body.first).to include("site-logo-light")
        end
      end

      it "renders with logo for dark mode when logo is provided", :aggregate_failures do
        Dir.mktmpdir do |temp_dir|
          logo_path = File.join(temp_dir, "logo.svg")
          File.write(logo_path, "<svg></svg>")
          File.write(File.join(temp_dir, "docyard.yml"), "branding:\n  logo: '#{logo_path}'")
          config = Docyard::Config.load(temp_dir)
          app_with_config = described_class.new(docs_path: docs_path, config: config)

          _status, _headers, body = app_with_config.call({ "PATH_INFO" => "/", "QUERY_STRING" => "" })

          expect(body.first).to include("src=\"/#{logo_path}\"")
          expect(body.first).to include("site-logo-dark")
        end
      end

      it "renders with favicon when provided in config" do
        Dir.mktmpdir do |temp_dir|
          favicon_path = File.join(temp_dir, "favicon.ico")
          File.write(favicon_path, "")
          File.write(File.join(temp_dir, "docyard.yml"), "branding:\n  favicon: '#{favicon_path}'")
          config = Docyard::Config.load(temp_dir)
          app_with_config = described_class.new(docs_path: docs_path, config: config)

          _status, _headers, body = app_with_config.call({ "PATH_INFO" => "/", "QUERY_STRING" => "" })

          expect(body.first).to include("href=\"/#{favicon_path}\"")
        end
      end
    end

    context "with asset request" do
      it "serves CSS assets with correct content type", :aggregate_failures do
        env = { "PATH_INFO" => "/_docyard/css/layout.css", "QUERY_STRING" => "" }

        status, headers, body = app.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/css; charset=utf-8")
        expect(body.first).to include(".page-wrapper")
      end

      it "returns 404 for non-existent assets" do
        env = { "PATH_INFO" => "/_docyard/nonexistent.css", "QUERY_STRING" => "" }

        status, _headers, _body = app.call(env)

        expect(status).to eq(404)
      end
    end

    context "with errors" do
      it "returns 500 and error page on exception", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }
        router = instance_double(Docyard::Router)
        allow(Docyard::Router).to receive(:new).and_return(router)
        allow(router).to receive(:resolve).and_raise(StandardError, "test error")

        new_app = described_class.new(docs_path: docs_path)
        status, headers, body = new_app.call(env)

        expect(status).to eq(500)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("Something went wrong")
      end
    end

    context "with tab navigation configured" do
      let(:tab_temp_dir) { Dir.mktmpdir }

      before do
        File.write(File.join(tab_temp_dir, "docyard.yml"), <<~YAML)
          tabs:
            - text: Guide
              href: /guide
            - text: API
              href: /api
        YAML
        FileUtils.mkdir_p(File.join(tab_temp_dir, "guide"))
        FileUtils.mkdir_p(File.join(tab_temp_dir, "api"))
        File.write(File.join(tab_temp_dir, "guide", "index.md"), "---\ntitle: Guide\n---\n# Guide")
        File.write(File.join(tab_temp_dir, "guide", "setup.md"), "---\ntitle: Setup\n---\n# Setup")
        File.write(File.join(tab_temp_dir, "api", "index.md"), "---\ntitle: API\n---\n# API")

        File.write(File.join(tab_temp_dir, "_sidebar.yml"), <<~YAML)
          - guide:
              items:
                - index: { text: Guide }
                - setup: { text: Setup }
          - api:
              items:
                - index: { text: API }
        YAML
      end

      after { FileUtils.rm_rf(tab_temp_dir) }

      it "renders tab navigation and marks correct tab as active", :aggregate_failures do
        config = Docyard::Config.load(tab_temp_dir)
        temp_app = described_class.new(docs_path: tab_temp_dir, config: config)
        _status, _headers, body = temp_app.call({ "PATH_INFO" => "/guide/setup", "QUERY_STRING" => "" })

        expect(body.first).to include("tab-bar")
        expect(body.first).to match(%r{href="/guide"[^>]*class="[^"]*is-active})
        expect(body.first).not_to match(%r{href="/api"[^>]*class="[^"]*is-active})
      end

      it "scopes sidebar to current tab section", :aggregate_failures do
        config = Docyard::Config.load(tab_temp_dir)
        temp_app = described_class.new(docs_path: tab_temp_dir, config: config)
        _status, _headers, body = temp_app.call({ "PATH_INFO" => "/guide/setup", "QUERY_STRING" => "" })
        sidebar_section = body.first[%r{class="sidebar".*?</nav>}m]

        expect(body.first).to include('href="/guide/setup"')
        expect(sidebar_section).not_to include('href="/api"')
      end
    end

    context "with build.base configuration" do
      it "ignores build.base and uses root path in dev server", :aggregate_failures do
        Dir.mktmpdir do |temp_dir|
          File.write(File.join(temp_dir, "docyard.yml"), <<~YAML)
            build:
              base: /docs/
          YAML
          File.write(File.join(temp_dir, "index.md"), "---\ntitle: Home\n---\n# Home")

          config = Docyard::Config.load(temp_dir)
          temp_app = described_class.new(docs_path: temp_dir, config: config)
          env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

          status, _headers, body = temp_app.call(env)

          expect(status).to eq(200)
          expect(body.first).to include('href="/"')
          expect(body.first).not_to include('href="/docs/"')
        end
      end
    end

    context "with custom HTML landing page" do
      it "serves index.html directly when it exists at root", :aggregate_failures do
        Dir.mktmpdir do |temp_dir|
          File.write(File.join(temp_dir, "index.html"), "<html><body>Custom Landing</body></html>")

          temp_app = described_class.new(docs_path: temp_dir)
          env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

          status, headers, body = temp_app.call(env)

          expect(status).to eq(200)
          expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
          expect(body.first).to eq("<html><body>Custom Landing</body></html>")
        end
      end

      it "falls back to index.md when index.html does not exist", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

        status, headers, body = app.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("Welcome to Docyard")
      end

      it "does not serve HTML files for non-root paths", :aggregate_failures do
        Dir.mktmpdir do |temp_dir|
          FileUtils.mkdir_p(File.join(temp_dir, "guide"))
          File.write(File.join(temp_dir, "guide", "index.html"), "<html>Guide HTML</html>")
          File.write(File.join(temp_dir, "guide", "index.md"), "---\n---\n# Guide")

          temp_app = described_class.new(docs_path: temp_dir)
          env = { "PATH_INFO" => "/guide", "QUERY_STRING" => "" }

          status, _headers, body = temp_app.call(env)

          expect(status).to eq(200)
          expect(body.first).to include("<h1")
          expect(body.first).not_to include("Guide HTML")
        end
      end
    end

    context "with open-in-editor endpoint" do
      before do
        allow(Docyard::EditorLauncher).to receive_messages(available?: true, open: true)
      end

      it "returns 200 when editor launches successfully", :aggregate_failures do
        env = {
          "PATH_INFO" => "/__docyard/open-in-editor",
          "QUERY_STRING" => "file=intro.md&line=10"
        }

        status, _headers, body = app.call(env)

        expect(status).to eq(200)
        expect(body.first).to eq("OK")
      end

      it "calls EditorLauncher.open with correct arguments" do
        env = {
          "PATH_INFO" => "/__docyard/open-in-editor",
          "QUERY_STRING" => "file=intro.md&line=10"
        }

        app.call(env)

        expect(Docyard::EditorLauncher).to have_received(:open)
          .with("#{docs_path}/intro.md", 10)
      end

      it "defaults line to 1 when not provided" do
        env = {
          "PATH_INFO" => "/__docyard/open-in-editor",
          "QUERY_STRING" => "file=intro.md"
        }

        app.call(env)

        expect(Docyard::EditorLauncher).to have_received(:open)
          .with("#{docs_path}/intro.md", 1)
      end

      it "returns 400 when file parameter is missing", :aggregate_failures do
        env = {
          "PATH_INFO" => "/__docyard/open-in-editor",
          "QUERY_STRING" => ""
        }

        status, _headers, body = app.call(env)

        expect(status).to eq(400)
        expect(body.first).to eq("Missing file parameter")
      end

      it "returns 404 when no editor is detected", :aggregate_failures do
        allow(Docyard::EditorLauncher).to receive(:available?).and_return(false)

        env = {
          "PATH_INFO" => "/__docyard/open-in-editor",
          "QUERY_STRING" => "file=intro.md"
        }

        status, _headers, body = app.call(env)

        expect(status).to eq(404)
        expect(body.first).to eq("No editor detected")
      end
    end

    context "with error overlay assets" do
      it "serves error-overlay.css", :aggregate_failures do
        env = {
          "PATH_INFO" => "/_docyard/error-overlay.css",
          "QUERY_STRING" => ""
        }

        status, headers, body = app.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/css")
        expect(body.first).to include(".docyard-error-overlay")
      end

      it "serves error-overlay.js", :aggregate_failures do
        env = {
          "PATH_INFO" => "/_docyard/error-overlay.js",
          "QUERY_STRING" => ""
        }

        status, headers, body = app.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/javascript")
        expect(body.first).to include("docyard-error-overlay")
      end

      it "returns 404 for non-existent overlay assets" do
        env = {
          "PATH_INFO" => "/_docyard/error-overlay-nonexistent.css",
          "QUERY_STRING" => ""
        }

        status, _headers, _body = app.call(env)

        expect(status).to eq(404)
      end
    end

    context "with error overlay injection in dev mode without diagnostics" do
      let(:dev_app) do
        described_class.new(docs_path: docs_path, sse_port: 4201, global_diagnostics: [])
      end

      it "does not inject overlay when no diagnostics exist", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

        _status, _headers, body = dev_app.call(env)

        expect(body.first).not_to include('id="docyard-error-overlay"')
        expect(body.first).not_to include("error-overlay.css")
      end
    end

    context "with error overlay injection in dev mode with diagnostics" do
      let(:global_diagnostics) do
        [
          Docyard::Diagnostic.new(
            severity: :error,
            category: :CONFIG,
            code: "TEST",
            message: "Test error"
          )
        ]
      end

      let(:dev_app) do
        described_class.new(docs_path: docs_path, sse_port: 4201, global_diagnostics: global_diagnostics)
      end

      it "injects overlay when diagnostics exist", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

        _status, _headers, body = dev_app.call(env)

        expect(body.first).to include('id="docyard-error-overlay"')
        expect(body.first).to include("error-overlay.css")
        expect(body.first).to include("error-overlay.js")
      end

      it "includes diagnostic data", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

        _status, _headers, body = dev_app.call(env)

        expect(body.first).to include("Test error")
        expect(body.first).to include('data-error-count="1"')
      end

      it "includes SSE port in overlay" do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

        _status, _headers, body = dev_app.call(env)

        expect(body.first).to include('data-sse-port="4201"')
      end
    end

    context "without dev mode (production)" do
      it "does not inject overlay even with diagnostics" do
        diagnostics = [
          Docyard::Diagnostic.new(
            severity: :error,
            category: :CONFIG,
            code: "TEST",
            message: "Test error"
          )
        ]

        prod_app = described_class.new(
          docs_path: docs_path,
          global_diagnostics: diagnostics
        )

        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }
        _status, _headers, body = prod_app.call(env)

        expect(body.first).not_to include("docyard-error-overlay")
      end
    end
  end
end
