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

  describe ".safe_path?" do
    let(:base_dir) { "/app/docs" }

    it "returns true for valid path within base directory" do
      expect(described_class.safe_path?("/app/docs/guide.md", base_dir)).to be true
    end

    it "returns true for nested path within base directory" do
      expect(described_class.safe_path?("/app/docs/api/v2/guide.md", base_dir)).to be true
    end

    it "returns true for exact base directory" do
      expect(described_class.safe_path?("/app/docs", base_dir)).to be true
    end

    it "returns false for path outside base directory" do
      expect(described_class.safe_path?("/etc/passwd", base_dir)).to be false
    end

    it "returns false for path traversal attempt" do
      expect(described_class.safe_path?("/app/docs/../etc/passwd", base_dir)).to be false
    end

    it "returns false for path that starts with base but is sibling" do
      expect(described_class.safe_path?("/app/docs_backup/file.md", base_dir)).to be false
    end

    it "returns false for nil requested path" do
      expect(described_class.safe_path?(nil, base_dir)).to be false
    end

    it "returns false for nil base dir" do
      expect(described_class.safe_path?("/app/docs/file.md", nil)).to be false
    end
  end

  describe ".resolve_safe_path" do
    let(:base_dir) { Dir.mktmpdir }

    after { FileUtils.rm_rf(base_dir) }

    it "returns expanded path for valid relative path" do
      result = described_class.resolve_safe_path("guide.md", base_dir)
      expect(result).to eq(File.join(base_dir, "guide.md"))
    end

    it "returns expanded path for nested relative path" do
      result = described_class.resolve_safe_path("api/guide.md", base_dir)
      expect(result).to eq(File.join(base_dir, "api/guide.md"))
    end

    it "returns nil for ../ traversal attempt" do
      result = described_class.resolve_safe_path("../../../etc/passwd", base_dir)
      expect(result).to be_nil
    end

    it "returns nil for URL-encoded traversal attempt" do
      result = described_class.resolve_safe_path("%2e%2e/%2e%2e/etc/passwd", base_dir)
      expect(result).to be_nil
    end

    it "returns nil for backslash traversal attempt" do
      result = described_class.resolve_safe_path("..\\..\\etc\\passwd", base_dir)
      expect(result).to be_nil
    end

    it "returns nil for path that resolves outside base" do
      result = described_class.resolve_safe_path("valid/../../../etc/passwd", base_dir)
      expect(result).to be_nil
    end

    it "returns nil for nil relative path" do
      result = described_class.resolve_safe_path(nil, base_dir)
      expect(result).to be_nil
    end

    it "returns nil for nil base dir" do
      result = described_class.resolve_safe_path("guide.md", nil)
      expect(result).to be_nil
    end
  end

  describe ".decode_path" do
    it "decodes URL-encoded characters" do
      expect(described_class.decode_path("%2e%2e")).to eq("..")
    end

    it "converts backslashes to forward slashes" do
      expect(described_class.decode_path("path\\to\\file")).to eq("path/to/file")
    end

    it "handles combined encoding and backslashes" do
      expect(described_class.decode_path("%2e%2e\\..")).to eq("../..")
    end

    it "handles normal paths unchanged" do
      expect(described_class.decode_path("docs/guide.md")).to eq("docs/guide.md")
    end

    it "returns original string on invalid encoding" do
      expect(described_class.decode_path("%ZZ")).to eq("%ZZ")
    end

    it "handles nil gracefully" do
      expect(described_class.decode_path(nil)).to eq("")
    end
  end
end
