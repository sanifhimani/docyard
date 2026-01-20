# frozen_string_literal: true

RSpec.describe Docyard::Renderer do
  let(:renderer) { described_class.new }

  describe "#render" do
    it "wraps content in layout with page title", :aggregate_failures do
      html = renderer.render(content: "<p>Test content</p>", page_title: "Test Page")

      expect(html).to include("<p>Test content</p>")
      expect(html).to include("<title>Test Page | Documentation</title>")
      expect(html).to include("<!DOCTYPE html>")
    end

    it "uses default title when not provided" do
      html = renderer.render(content: "<p>Content</p>")

      expect(html).to include("<title>Documentation | Documentation</title>")
    end

    it "renders with logo when custom logo is set", :aggregate_failures do
      html = renderer.render(content: "<p>Content</p>", branding: { logo: "logo.svg", has_custom_logo: true })

      expect(html).to include('src="/logo.svg"')
      expect(html).to include("site-logo-light")
    end

    it "renders with dark mode logo when provided", :aggregate_failures do
      html = renderer.render(
        content: "<p>Content</p>",
        branding: {
          logo: "logo.svg",
          logo_dark: "logo-dark.svg",
          has_custom_logo: true
        }
      )

      expect(html).to include('src="/logo-dark.svg"')
      expect(html).to include("site-logo-dark")
    end

    it "renders with favicon when provided" do
      html = renderer.render(content: "<p>Content</p>", branding: { favicon: "favicon.ico" })

      expect(html).to include('href="/favicon.ico"')
    end

    it "renders title only when no custom logo is set", :aggregate_failures do
      html = renderer.render(content: "<p>Content</p>", branding: { has_custom_logo: false })

      expect(html).to include("header-title")
      expect(html).not_to include("site-logo")
    end

    it "renders logo only when custom logo is set", :aggregate_failures do
      html = renderer.render(content: "<p>Content</p>", branding: { has_custom_logo: true, logo: "custom-logo.svg" })

      expect(html).to include("site-logo")
      expect(html).to include('src="/custom-logo.svg"')
      expect(html).not_to include("header-title")
    end

    it "renders with navigation components", :aggregate_failures do
      navigation = {
        sidebar_html: "<nav>Sidebar</nav>",
        prev_next_html: "<footer>Prev/Next</footer>",
        toc: [{ text: "Heading", id: "heading", level: 2, children: [] }]
      }
      html = renderer.render(content: "<p>Content</p>", navigation: navigation)

      expect(html).to include("<nav>Sidebar</nav>", "<footer>Prev/Next</footer>", "Heading")
    end
  end

  describe "#render_partial" do
    it "renders a partial template", :aggregate_failures do
      html = renderer.render_partial("_theme_toggle")

      expect(html).to include("theme-toggle")
      expect(html).to include("theme-toggle-sun")
    end

    it "renders a partial with locals", :aggregate_failures do
      html = renderer.render_partial("_nav_item", item_content: "<a href='/test'>Test Link</a>")

      expect(html).to include("<li>")
      expect(html).to include("Test Link")
      expect(html).to include("/test")
    end

    it "accepts valid variable names" do
      expect do
        renderer.render_partial("_nav_item", item_content: "test")
      end.not_to raise_error
    end

    it "rejects variable names starting with numbers" do
      expect { renderer.render_partial("_nav_item", "123invalid": "value") }
        .to raise_error(ArgumentError, /Invalid variable name/)
    end

    it "rejects variable names with special characters" do
      expect { renderer.render_partial("_nav_item", "name-with-dash": "value") }
        .to raise_error(ArgumentError, /Invalid variable name/)
    end

    it "rejects variable names with spaces" do
      expect { renderer.render_partial("_nav_item", "name with space": "value") }
        .to raise_error(ArgumentError, /Invalid variable name/)
    end
  end

  describe "#render_not_found" do
    it "renders 404 page", :aggregate_failures do
      html = renderer.render_not_found

      expect(html).to include("404")
      expect(html).to include("Page Not Found")
    end
  end

  describe "announcement banner" do
    context "when announcement is nil" do
      it "does not render the banner" do
        html = renderer.render(content: "<p>Content</p>", branding: { announcement: nil })

        expect(html).not_to include('<div class="docyard-announcement"')
      end
    end

    context "when announcement is configured" do
      let(:announcement) do
        {
          text: "New version available!",
          link: "/changelog",
          button: { text: "Learn more", link: "/features" },
          dismissible: true
        }
      end

      it "renders the announcement banner", :aggregate_failures do
        html = renderer.render(content: "<p>Content</p>", branding: { announcement: announcement })

        expect(html).to include("docyard-announcement")
        expect(html).to include("New version available!")
        expect(html).to include('href="/changelog"')
        expect(html).to include("Learn more")
        expect(html).to include('href="/features"')
      end

      it "renders dismiss button when dismissible" do
        html = renderer.render(content: "<p>Content</p>", branding: { announcement: announcement })

        expect(html).to include("docyard-announcement__dismiss")
      end
    end

    context "when announcement is not dismissible" do
      let(:announcement) do
        {
          text: "Important notice",
          dismissible: false
        }
      end

      it "does not render dismiss button" do
        html = renderer.render(content: "<p>Content</p>", branding: { announcement: announcement })

        expect(html).not_to include("docyard-announcement__dismiss")
      end
    end
  end

  describe "tab navigation" do
    let(:tabs) do
      [
        { text: "Guide", href: "/guide", icon: "book", external: false },
        { text: "API", href: "/api", icon: nil, external: false }
      ]
    end

    context "when current path matches tab href exactly" do
      it "marks the tab as active" do
        html = renderer.render(
          content: "<p>Content</p>",
          branding: { tabs: tabs, has_tabs: true },
          current_path: "/guide"
        )

        expect(html).to match(%r{href="/guide"[^>]*class="[^"]*is-active})
      end
    end

    context "when current path is under tab href" do
      it "marks the tab as active" do
        html = renderer.render(
          content: "<p>Content</p>",
          branding: { tabs: tabs, has_tabs: true },
          current_path: "/guide/setup"
        )

        expect(html).to match(%r{href="/guide"[^>]*class="[^"]*is-active})
      end
    end

    context "when current path does not match tab href" do
      it "does not mark the tab as active" do
        html = renderer.render(
          content: "<p>Content</p>",
          branding: { tabs: tabs, has_tabs: true },
          current_path: "/api/reference"
        )

        expect(html).not_to match(%r{href="/guide"[^>]*class="[^"]*is-active})
      end
    end

    context "when tab is external link" do
      let(:tabs) do
        [{ text: "GitHub", href: "https://github.com", external: true }]
      end

      it "does not mark external tabs as active" do
        html = renderer.render(
          content: "<p>Content</p>",
          branding: { tabs: tabs, has_tabs: true },
          current_path: "/"
        )

        expect(html).not_to match(%r{href="https://github\.com"[^>]*class="[^"]*is-active})
      end
    end

    context "when has_tabs is false" do
      it "does not render tab navigation" do
        html = renderer.render(
          content: "<p>Content</p>",
          branding: { tabs: tabs, has_tabs: false },
          current_path: "/guide"
        )

        expect(html).not_to include("tab-bar")
      end
    end

    context "when has_tabs is true" do
      it "renders tab navigation" do
        html = renderer.render(
          content: "<p>Content</p>",
          branding: { tabs: tabs, has_tabs: true },
          current_path: "/guide"
        )

        expect(html).to include("tab-bar")
      end
    end
  end

  describe "OG meta tags" do
    context "when site_url is not configured" do
      it "does not render OG meta tags", :aggregate_failures do
        html = renderer.render(content: "<p>Content</p>", branding: {})

        expect(html).not_to include('property="og:')
        expect(html).not_to include('name="twitter:')
        expect(html).not_to include('rel="canonical"')
      end
    end

    context "when site_url is configured" do
      let(:branding) do
        {
          site_url: "https://example.com",
          site_title: "My Docs"
        }
      end

      it "renders canonical link", :aggregate_failures do
        html = renderer.render(content: "<p>Content</p>", branding: branding, current_path: "/guide/intro")

        expect(html).to include('<link rel="canonical" href="https://example.com/guide/intro">')
      end

      it "renders OG meta tags", :aggregate_failures do
        html = renderer.render(
          content: "<p>Content</p>",
          page_title: "Test Page",
          branding: branding,
          current_path: "/test"
        )

        expect(html).to include('property="og:type" content="website"')
        expect(html).to include('property="og:site_name" content="My Docs"')
        expect(html).to include('property="og:title" content="Test Page"')
        expect(html).to include('property="og:url" content="https://example.com/test"')
      end

      it "renders Twitter card meta tags", :aggregate_failures do
        html = renderer.render(
          content: "<p>Content</p>",
          page_title: "Test Page",
          branding: branding
        )

        expect(html).to include('name="twitter:card" content="summary"')
        expect(html).to include('name="twitter:title" content="Test Page"')
      end
    end

    context "with description" do
      let(:branding) { { site_url: "https://example.com", site_description: "Site description" } }

      it "renders OG and Twitter description from page description when provided", :aggregate_failures do
        html = renderer.render(
          content: "<p>Content</p>",
          page_description: "Page-specific description",
          branding: branding
        )

        expect(html).to include('property="og:description" content="Page-specific description"')
        expect(html).to include('name="twitter:description" content="Page-specific description"')
      end

      it "falls back to site description when page description is nil" do
        html = renderer.render(content: "<p>Content</p>", branding: branding)

        expect(html).to include('property="og:description" content="Site description"')
      end
    end

    context "with og_image" do
      let(:branding) { { site_url: "https://example.com", og_image: "/images/og.png" } }

      it "renders OG image with absolute URL", :aggregate_failures do
        html = renderer.render(content: "<p>Content</p>", branding: branding)

        expect(html).to include('property="og:image" content="https://example.com/images/og.png"')
        expect(html).to include('name="twitter:image" content="https://example.com/images/og.png"')
      end

      it "uses summary_large_image card type when image is present" do
        html = renderer.render(content: "<p>Content</p>", branding: branding)

        expect(html).to include('name="twitter:card" content="summary_large_image"')
      end

      it "preserves absolute image URLs" do
        branding_with_absolute = branding.merge(og_image: "https://cdn.example.com/og.png")
        html = renderer.render(content: "<p>Content</p>", branding: branding_with_absolute)

        expect(html).to include('property="og:image" content="https://cdn.example.com/og.png"')
      end

      it "uses page og_image over site og_image" do
        html = renderer.render(
          content: "<p>Content</p>",
          page_og_image: "/images/page-og.png",
          branding: branding
        )

        expect(html).to include('property="og:image" content="https://example.com/images/page-og.png"')
      end
    end

    context "with twitter handle" do
      it "renders twitter:site with @ prefix" do
        branding = { site_url: "https://example.com", twitter: "docyard" }
        html = renderer.render(content: "<p>Content</p>", branding: branding)

        expect(html).to include('name="twitter:site" content="@docyard"')
      end

      it "normalizes twitter handle with existing @", :aggregate_failures do
        branding = { site_url: "https://example.com", twitter: "@docyard" }
        html = renderer.render(content: "<p>Content</p>", branding: branding)

        expect(html).to include('name="twitter:site" content="@docyard"')
        expect(html).not_to include("@@")
      end
    end

    context "with trailing slashes in URLs" do
      it "handles site_url with trailing slash", :aggregate_failures do
        branding = { site_url: "https://example.com/" }
        html = renderer.render(content: "<p>Content</p>", branding: branding, current_path: "/guide")

        expect(html).to include('href="https://example.com/guide"')
        expect(html).not_to include("https://example.com//")
      end
    end
  end

  describe "#render_file" do
    let(:temp_file) { Tempfile.new(["test", ".md"]) }

    after { temp_file.unlink }

    context "with frontmatter" do
      before do
        temp_file.write("---\ntitle: Test\n---\n# Hello")
        temp_file.rewind
      end

      it "renders markdown with title from frontmatter", :aggregate_failures do
        html = renderer.render_file(temp_file.path)

        expect(html).to include("<h1")
        expect(html).to include("Hello")
        expect(html).to include("<title>Test | Documentation</title>")
      end
    end

    context "without frontmatter" do
      before do
        temp_file.write("# Hello World")
        temp_file.rewind
      end

      it "uses default title" do
        html = renderer.render_file(temp_file.path)

        expect(html).to include("<title>Documentation | Documentation</title>")
      end
    end

    context "with markdown links" do
      before do
        temp_file.write("# Page\n\n[Link to page](page.md)\n\n[Nested](guide/setup.md)")
        temp_file.rewind
      end

      it "strips .md extensions from links (VitePress-style)", :aggregate_failures do
        html = renderer.render_file(temp_file.path)

        expect(html).to include('href="page"')
        expect(html).to include('href="guide/setup"')
        expect(html).not_to include('href="page.md"')
        expect(html).not_to include('href="guide/setup.md"')
      end
    end
  end

  describe "#render_for_search" do
    let(:temp_file) { Tempfile.new(["test", ".md"]) }

    after { temp_file.unlink }

    context "with standard markdown content" do
      before do
        temp_file.write("---\ntitle: Search Test\n---\n# Hello\n\nThis is searchable content.")
        temp_file.rewind
      end

      it "generates minimal HTML with title and content", :aggregate_failures do
        html = renderer.render_for_search(temp_file.path)

        expect(html).to include("<!DOCTYPE html>")
        expect(html).to include("<title>Search Test</title>")
        expect(html).to include("<h1")
        expect(html).to include("searchable content")
      end

      it "wraps content in data-pagefind-body for indexing" do
        html = renderer.render_for_search(temp_file.path)

        expect(html).to include("<main data-pagefind-body>")
      end

      it "does not include sidebar, footer, or scripts", :aggregate_failures do
        html = renderer.render_for_search(temp_file.path)

        expect(html).not_to include("sidebar")
        expect(html).not_to include("footer")
        expect(html).not_to include("<script")
        expect(html).not_to include("stylesheet")
      end
    end

    context "with special characters in title" do
      before do
        temp_file.write("---\ntitle: Test & \"Quotes\" <Tags>\n---\n# Content")
        temp_file.rewind
      end

      it "escapes HTML entities in title" do
        html = renderer.render_for_search(temp_file.path)

        expect(html).to include("<title>Test &amp; &quot;Quotes&quot; &lt;Tags&gt;</title>")
      end
    end

    context "with markdown links" do
      before do
        temp_file.write("---\ntitle: Links\n---\n# Page\n\n[Link](page.md)")
        temp_file.rewind
      end

      it "strips .md extensions from links", :aggregate_failures do
        html = renderer.render_for_search(temp_file.path)

        expect(html).to include('href="page"')
        expect(html).not_to include(".md")
      end
    end

    context "without frontmatter title" do
      before do
        temp_file.write("# Just Content\n\nNo frontmatter here.")
        temp_file.rewind
      end

      it "uses default title" do
        html = renderer.render_for_search(temp_file.path)

        expect(html).to include("<title>Documentation</title>")
      end
    end
  end
end
