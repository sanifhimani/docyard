# frozen_string_literal: true

RSpec.describe Docyard::Utils::PathUtils do
  describe ".sanitize_url_path" do
    it "strips leading slash" do
      expect(described_class.sanitize_url_path("/guide")).to eq("guide")
    end

    it "strips trailing slash" do
      expect(described_class.sanitize_url_path("guide/")).to eq("guide")
    end

    it "strips both slashes" do
      expect(described_class.sanitize_url_path("/guide/")).to eq("guide")
    end

    it "returns index for empty string" do
      expect(described_class.sanitize_url_path("")).to eq("index")
    end

    it "returns index for root path" do
      expect(described_class.sanitize_url_path("/")).to eq("index")
    end

    it "strips .md extension" do
      expect(described_class.sanitize_url_path("/guide.md")).to eq("guide")
    end

    it "handles nested paths" do
      expect(described_class.sanitize_url_path("/api/v2/auth")).to eq("api/v2/auth")
    end

    it "handles nil gracefully" do
      expect(described_class.sanitize_url_path(nil)).to eq("index")
    end
  end

  describe ".markdown_file_to_url" do
    it "converts root index to /" do
      expect(described_class.markdown_file_to_url("docs/index.md", "docs")).to eq("/")
    end

    it "converts top-level file to /filename" do
      expect(described_class.markdown_file_to_url("docs/guide.md", "docs")).to eq("/guide")
    end

    it "converts nested file to /dir/filename" do
      expect(described_class.markdown_file_to_url("docs/guide/intro.md", "docs")).to eq("/guide/intro")
    end

    it "converts directory index to /dirname" do
      expect(described_class.markdown_file_to_url("docs/guide/index.md", "docs")).to eq("/guide")
    end

    it "converts deeply nested file" do
      expect(described_class.markdown_file_to_url("docs/api/v2/auth/login.md", "docs")).to eq("/api/v2/auth/login")
    end

    it "converts deeply nested index" do
      expect(described_class.markdown_file_to_url("docs/api/v2/index.md", "docs")).to eq("/api/v2")
    end

    it "handles custom docs path" do
      expect(described_class.markdown_file_to_url("content/guide.md", "content")).to eq("/guide")
    end
  end

  describe ".relative_path_to_url" do
    it "converts root index to /" do
      expect(described_class.relative_path_to_url("index.md")).to eq("/")
    end

    it "converts top-level file to /filename" do
      expect(described_class.relative_path_to_url("guide.md")).to eq("/guide")
    end

    it "converts nested file to /dir/filename" do
      expect(described_class.relative_path_to_url("guide/intro.md")).to eq("/guide/intro")
    end

    it "converts directory index to /dirname" do
      expect(described_class.relative_path_to_url("guide/index.md")).to eq("/guide")
    end
  end

  describe ".markdown_to_html_output" do
    it "converts root index to output_dir/index.html" do
      expect(described_class.markdown_to_html_output("index.md", "dist")).to eq("dist/./index.html")
    end

    it "converts top-level file to output_dir/filename/index.html" do
      expect(described_class.markdown_to_html_output("guide.md", "dist")).to eq("dist/./guide/index.html")
    end

    it "converts nested file to output_dir/dir/filename/index.html" do
      expect(described_class.markdown_to_html_output("guide/intro.md", "dist")).to eq("dist/guide/intro/index.html")
    end

    it "converts directory index to output_dir/dirname/index.html" do
      expect(described_class.markdown_to_html_output("guide/index.md", "dist")).to eq("dist/guide/index.html")
    end

    it "converts deeply nested file" do
      result = described_class.markdown_to_html_output("api/v2/auth/login.md", "dist")
      expect(result).to eq("dist/api/v2/auth/login/index.html")
    end

    it "handles custom output directory" do
      result = described_class.markdown_to_html_output("guide.md", "/var/www/html")
      expect(result).to eq("/var/www/html/./guide/index.html")
    end
  end
end
