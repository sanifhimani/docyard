# frozen_string_literal: true

RSpec.describe Docyard::Utils::GitInfo do
  let(:repo_url) { "https://github.com/docyard/docyard" }
  let(:branch) { "main" }
  let(:edit_path) { "docs" }
  let(:git_info) { described_class.new(repo_url: repo_url, branch: branch, edit_path: edit_path) }

  describe "#edit_url" do
    it "returns nil when repo_url is nil" do
      info = described_class.new(repo_url: nil)
      expect(info.edit_url("/path/to/docs/getting-started.md")).to be_nil
    end

    it "returns nil when file_path is nil" do
      expect(git_info.edit_url(nil)).to be_nil
    end

    it "returns nil when file_path does not contain docs/" do
      expect(git_info.edit_url("/path/to/other/file.md")).to be_nil
    end

    it "builds correct edit URL for GitHub" do
      file_path = "/project/docs/getting-started/index.md"
      expected = "https://github.com/docyard/docyard/edit/main/docs/getting-started/index.md"
      expect(git_info.edit_url(file_path)).to eq(expected)
    end

    it "handles repo URLs with trailing slash" do
      info = described_class.new(repo_url: "https://github.com/docyard/docyard/", branch: "main", edit_path: "docs")
      file_path = "/project/docs/page.md"
      expected = "https://github.com/docyard/docyard/edit/main/docs/page.md"
      expect(info.edit_url(file_path)).to eq(expected)
    end

    it "uses custom branch" do
      info = described_class.new(repo_url: repo_url, branch: "develop", edit_path: "docs")
      file_path = "/project/docs/page.md"
      expected = "https://github.com/docyard/docyard/edit/develop/docs/page.md"
      expect(info.edit_url(file_path)).to eq(expected)
    end

    it "uses custom edit path" do
      info = described_class.new(repo_url: repo_url, branch: "main", edit_path: "documentation")
      file_path = "/project/docs/page.md"
      expected = "https://github.com/docyard/docyard/edit/main/documentation/page.md"
      expect(info.edit_url(file_path)).to eq(expected)
    end
  end

  describe "#last_updated" do
    it "returns nil when file_path is nil" do
      expect(git_info.last_updated(nil)).to be_nil
    end

    it "returns nil when file does not exist" do
      expect(git_info.last_updated("/nonexistent/file.md")).to be_nil
    end

    it "returns nil when git has no commits for file" do
      temp_file = Tempfile.new(["test", ".md"])
      temp_file.write("# Test")
      temp_file.rewind
      allow(git_info).to receive(:`).and_return("")
      expect(git_info.last_updated(temp_file.path)).to be_nil
    ensure
      temp_file.unlink
    end

    context "with git commit data" do
      it "returns hash with time object" do
        temp_file = Tempfile.new(["test", ".md"])
        temp_file.write("# Test")
        temp_file.rewind
        timestamp = Time.new(2026, 1, 13, 14, 32, 0, "-05:00")
        allow(git_info).to receive(:`).and_return(timestamp.iso8601)
        result = git_info.last_updated(temp_file.path)
        expect(result[:time]).to be_a(Time)
      ensure
        temp_file.unlink
      end

      it "returns hash with ISO8601 string" do
        temp_file = Tempfile.new(["test", ".md"])
        temp_file.write("# Test")
        temp_file.rewind
        timestamp = Time.new(2026, 1, 13, 14, 32, 0, "-05:00")
        allow(git_info).to receive(:`).and_return(timestamp.iso8601)
        result = git_info.last_updated(temp_file.path)
        expect(result[:iso]).to match(/^\d{4}-\d{2}-\d{2}T/)
      ensure
        temp_file.unlink
      end

      it "returns hash with formatted string" do
        temp_file = Tempfile.new(["test", ".md"])
        temp_file.write("# Test")
        temp_file.rewind
        timestamp = Time.new(2026, 1, 13, 14, 32, 0, "-05:00")
        allow(git_info).to receive(:`).and_return(timestamp.iso8601)
        result = git_info.last_updated(temp_file.path)
        expect(result[:formatted]).to include("January 13, 2026")
      ensure
        temp_file.unlink
      end

      it "returns hash with short formatted string" do
        temp_file = Tempfile.new(["test", ".md"])
        temp_file.write("# Test")
        temp_file.rewind
        timestamp = Time.new(2026, 1, 13, 14, 32, 0, "-05:00")
        allow(git_info).to receive(:`).and_return(timestamp.iso8601)
        result = git_info.last_updated(temp_file.path)
        expect(result[:formatted_short]).to eq("Jan 13, 2026")
      ensure
        temp_file.unlink
      end

      it "returns hash with relative time" do
        temp_file = Tempfile.new(["test", ".md"])
        temp_file.write("# Test")
        temp_file.rewind
        timestamp = Time.new(2026, 1, 13, 14, 32, 0, "-05:00")
        allow(git_info).to receive(:`).and_return(timestamp.iso8601)
        result = git_info.last_updated(temp_file.path)
        expect(result[:relative]).to be_a(String)
      ensure
        temp_file.unlink
      end
    end
  end

  describe "relative time formatting" do
    let(:git_info_instance) { described_class.new(repo_url: repo_url) }

    it "returns 'just now' for times less than a minute ago" do
      time = Time.now - 30
      result = git_info_instance.send(:relative_time, time)
      expect(result).to eq("just now")
    end

    it "returns minutes ago for times less than an hour ago" do
      time = Time.now - 300
      result = git_info_instance.send(:relative_time, time)
      expect(result).to eq("5 minutes ago")
    end

    it "returns singular minute for exactly 1 minute" do
      time = Time.now - 90
      result = git_info_instance.send(:relative_time, time)
      expect(result).to eq("1 minute ago")
    end

    it "returns hours ago for times less than a day ago" do
      time = Time.now - 7200
      result = git_info_instance.send(:relative_time, time)
      expect(result).to eq("2 hours ago")
    end

    it "returns days ago for times less than a week ago" do
      time = Time.now - (86_400 * 3)
      result = git_info_instance.send(:relative_time, time)
      expect(result).to eq("3 days ago")
    end

    it "returns weeks ago for times less than a month ago" do
      time = Time.now - (604_800 * 2)
      result = git_info_instance.send(:relative_time, time)
      expect(result).to eq("2 weeks ago")
    end

    it "returns months ago for times less than a year ago" do
      time = Time.now - (2_592_000 * 3)
      result = git_info_instance.send(:relative_time, time)
      expect(result).to eq("3 months ago")
    end

    it "returns years ago for times more than a year ago" do
      time = Time.now - (31_536_000 * 2)
      result = git_info_instance.send(:relative_time, time)
      expect(result).to eq("2 years ago")
    end
  end
end
