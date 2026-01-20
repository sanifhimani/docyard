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

    it "returns nil when not in a git repository" do
      temp_file = Tempfile.new(["test", ".md"])
      temp_file.write("# Test")
      temp_file.rewind
      allow(described_class).to receive(:git_repository?).and_return(false)

      expect(git_info.last_updated(temp_file.path)).to be_nil
    ensure
      temp_file.unlink
    end

    it "returns nil when git has no commits for file" do
      temp_file = Tempfile.new(["test", ".md"])
      temp_file.write("# Test")
      temp_file.rewind
      failure_status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture3).and_return(["", "", failure_status])
      expect(git_info.last_updated(temp_file.path)).to be_nil
    ensure
      temp_file.unlink
    end

    context "with git commit data" do
      let(:success_status) { instance_double(Process::Status, success?: true) }

      it "returns hash with time object" do
        temp_file = Tempfile.new(["test", ".md"])
        temp_file.write("# Test")
        temp_file.rewind
        timestamp = Time.new(2026, 1, 13, 14, 32, 0, "-05:00")
        allow(Open3).to receive(:capture3).and_return([timestamp.iso8601, "", success_status])
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
        allow(Open3).to receive(:capture3).and_return([timestamp.iso8601, "", success_status])
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
        allow(Open3).to receive(:capture3).and_return([timestamp.iso8601, "", success_status])
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
        allow(Open3).to receive(:capture3).and_return([timestamp.iso8601, "", success_status])
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
        allow(Open3).to receive(:capture3).and_return([timestamp.iso8601, "", success_status])
        result = git_info.last_updated(temp_file.path)
        expect(result[:relative]).to be_a(String)
      ensure
        temp_file.unlink
      end
    end
  end

  describe ".git_repository?" do
    it "returns true when .git directory exists" do
      allow(File).to receive(:directory?).with(".git").and_return(true)

      expect(described_class.git_repository?).to be true
    end

    it "falls back to git rev-parse when .git directory does not exist" do
      allow(File).to receive(:directory?).with(".git").and_return(false)
      allow(described_class).to receive(:system).and_return(true)

      expect(described_class.git_repository?).to be true
    end

    it "returns false when not in a git repository" do
      allow(File).to receive(:directory?).with(".git").and_return(false)
      allow(described_class).to receive(:system).and_return(false)

      expect(described_class.git_repository?).to be false
    end
  end

  describe ".prefetch_timestamps" do
    after { described_class.clear_cache }

    context "when not in a git repository" do
      it "returns early without calling git" do
        allow(described_class).to receive(:git_repository?).and_return(false)
        allow(Open3).to receive(:capture3)

        described_class.prefetch_timestamps("docs")

        expect(Open3).not_to have_received(:capture3)
      end
    end

    it "populates the timestamp cache from git log", :aggregate_failures do
      success_status = instance_double(Process::Status, success?: true)
      git_output = "2026-01-15T10:00:00-05:00\n\ndocs/guide.md\ndocs/index.md\n"
      allow(Open3).to receive(:capture3)
        .with("git", "log", "--pretty=format:%cI", "--name-only", "--", "docs/")
        .and_return([git_output, "", success_status])

      described_class.prefetch_timestamps("docs")

      expect(described_class.cached_timestamp("docs/guide.md")).to be_a(Time)
      expect(described_class.cached_timestamp("docs/index.md")).to be_a(Time)
    end

    it "keeps first (most recent) timestamp for each file" do
      success_status = instance_double(Process::Status, success?: true)
      git_output = "2026-01-15T10:00:00-05:00\n\ndocs/guide.md\n\n2026-01-10T09:00:00-05:00\n\ndocs/guide.md\n"
      allow(Open3).to receive(:capture3)
        .with("git", "log", "--pretty=format:%cI", "--name-only", "--", "docs/")
        .and_return([git_output, "", success_status])

      described_class.prefetch_timestamps("docs")

      expect(described_class.cached_timestamp("docs/guide.md").day).to eq(15)
    end

    it "returns empty hash when git command fails" do
      failure_status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture3).and_return(["", "error", failure_status])

      described_class.prefetch_timestamps("docs")

      expect(described_class.cached_timestamp("docs/guide.md")).to be_nil
    end
  end

  describe ".clear_cache" do
    it "removes all cached timestamps" do
      success_status = instance_double(Process::Status, success?: true)
      git_output = "2026-01-15T10:00:00-05:00\n\ndocs/guide.md\n"
      allow(Open3).to receive(:capture3).and_return([git_output, "", success_status])

      described_class.prefetch_timestamps("docs")
      described_class.clear_cache

      expect(described_class.cached_timestamp("docs/guide.md")).to be_nil
    end
  end

  describe "#last_updated with cache" do
    after { described_class.clear_cache }

    it "uses cached timestamp when available" do
      temp_file = Tempfile.new(["guide", ".md"])
      temp_file.write("# Guide")
      temp_file.close

      timestamp = Time.new(2026, 1, 15, 10, 0, 0, "-05:00")
      described_class.instance_variable_set(:@timestamp_cache, { temp_file.path => timestamp })

      result = git_info.last_updated(temp_file.path)
      expect(result[:time]).to eq(timestamp)
    ensure
      temp_file&.unlink
      described_class.clear_cache
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
