# frozen_string_literal: true

RSpec.describe Docyard::EditorLauncher do
  describe ".detect" do
    context "when VISUAL environment variable is set" do
      it "detects VS Code from VISUAL" do
        allow(ENV).to receive(:fetch).with("VISUAL", nil).and_return("/usr/local/bin/code")
        allow(ENV).to receive(:fetch).with("EDITOR", nil).and_return(nil)

        expect(described_class.detect).to eq(:vscode)
      end

      it "detects Cursor from VISUAL" do
        allow(ENV).to receive(:fetch).with("VISUAL", nil).and_return("/usr/local/bin/cursor")
        allow(ENV).to receive(:fetch).with("EDITOR", nil).and_return(nil)

        expect(described_class.detect).to eq(:cursor)
      end

      it "detects Zed from VISUAL" do
        allow(ENV).to receive(:fetch).with("VISUAL", nil).and_return("/usr/local/bin/zed")
        allow(ENV).to receive(:fetch).with("EDITOR", nil).and_return(nil)

        expect(described_class.detect).to eq(:zed)
      end

      it "detects vim from VISUAL" do
        allow(ENV).to receive(:fetch).with("VISUAL", nil).and_return("/usr/bin/vim")
        allow(ENV).to receive(:fetch).with("EDITOR", nil).and_return(nil)

        expect(described_class.detect).to eq(:vim)
      end

      it "detects nvim from VISUAL" do
        allow(ENV).to receive(:fetch).with("VISUAL", nil).and_return("/usr/bin/nvim")
        allow(ENV).to receive(:fetch).with("EDITOR", nil).and_return(nil)

        expect(described_class.detect).to eq(:vim)
      end
    end

    context "when EDITOR environment variable is set" do
      it "detects editor from EDITOR when VISUAL not set" do
        allow(ENV).to receive(:fetch).with("VISUAL", nil).and_return(nil)
        allow(ENV).to receive(:fetch).with("EDITOR", nil).and_return("/usr/local/bin/code")

        expect(described_class.detect).to eq(:vscode)
      end
    end

    context "when environment variables are not set" do
      before do
        allow(ENV).to receive(:fetch).with("VISUAL", nil).and_return(nil)
        allow(ENV).to receive(:fetch).with("EDITOR", nil).and_return(nil)
      end

      it "falls back to process detection when pgrep exists" do
        allow(described_class).to receive(:system)
          .with("which", "pgrep", out: File::NULL, err: File::NULL)
          .and_return(true)
        allow(described_class).to receive(:system)
          .with("pgrep", "-x", "code", out: File::NULL, err: File::NULL)
          .and_return(true)

        expect(described_class.detect).to eq(:vscode)
      end

      it "returns nil when pgrep does not exist" do
        allow(described_class).to receive(:system)
          .with("which", "pgrep", out: File::NULL, err: File::NULL)
          .and_return(false)

        expect(described_class.detect).to be_nil
      end

      it "returns nil when no matching process found" do
        allow(described_class).to receive(:system)
          .with("which", "pgrep", out: File::NULL, err: File::NULL)
          .and_return(true)
        allow(described_class).to receive(:system)
          .with("pgrep", "-x", anything, out: File::NULL, err: File::NULL)
          .and_return(false)
        allow(described_class).to receive(:system)
          .with("pgrep", "-f", anything, out: File::NULL, err: File::NULL)
          .and_return(false)

        expect(described_class.detect).to be_nil
      end
    end
  end

  describe ".available?" do
    it "returns true when an editor is detected" do
      allow(described_class).to receive(:detect).and_return(:vscode)

      expect(described_class.available?).to be true
    end

    it "returns false when no editor is detected" do
      allow(described_class).to receive(:detect).and_return(nil)

      expect(described_class.available?).to be false
    end
  end

  describe ".open" do
    context "when editor is available" do
      before do
        allow(described_class).to receive(:detect).and_return(:vscode)
        allow(described_class).to receive(:spawn)
      end

      it "launches VS Code with correct arguments" do
        described_class.open("/path/to/file.md", 10)

        expect(described_class).to have_received(:spawn)
          .with("code", "--goto", "/path/to/file.md:10", %i[out err] => File::NULL)
      end

      it "defaults to line 1 when line not specified" do
        described_class.open("/path/to/file.md")

        expect(described_class).to have_received(:spawn)
          .with("code", "--goto", "/path/to/file.md:1", %i[out err] => File::NULL)
      end

      it "returns true on success" do
        expect(described_class.open("/path/to/file.md", 5)).to be true
      end
    end

    context "when editor is not available" do
      before do
        allow(described_class).to receive(:detect).and_return(nil)
      end

      it "returns false" do
        expect(described_class.open("/path/to/file.md")).to be false
      end

      it "does not attempt to spawn" do
        allow(described_class).to receive(:spawn)

        described_class.open("/path/to/file.md")

        expect(described_class).not_to have_received(:spawn)
      end
    end

    context "when spawn fails" do
      before do
        allow(described_class).to receive(:detect).and_return(:vscode)
        allow(described_class).to receive(:spawn).and_raise(StandardError, "spawn failed")
        allow(Docyard.logger).to receive(:warn)
      end

      it "returns false" do
        expect(described_class.open("/path/to/file.md")).to be false
      end

      it "logs a warning" do
        described_class.open("/path/to/file.md")

        expect(Docyard.logger).to have_received(:warn).with(/Failed to open editor/)
      end
    end
  end

  describe "editor command generation" do
    before do
      allow(described_class).to receive(:spawn)
    end

    it "generates correct command for Cursor" do
      allow(described_class).to receive(:detect).and_return(:cursor)

      described_class.open("file.md", 5)

      expect(described_class).to have_received(:spawn)
        .with("cursor", "--goto", "file.md:5", %i[out err] => File::NULL)
    end

    it "generates correct command for Zed" do
      allow(described_class).to receive(:detect).and_return(:zed)

      described_class.open("file.md", 5)

      expect(described_class).to have_received(:spawn)
        .with("zed", "file.md:5", %i[out err] => File::NULL)
    end

    it "generates correct command for WebStorm" do
      allow(described_class).to receive(:detect).and_return(:webstorm)

      described_class.open("file.md", 5)

      expect(described_class).to have_received(:spawn)
        .with("webstorm", "--line", "5", "file.md", %i[out err] => File::NULL)
    end

    it "generates correct command for vim using nvim when available" do
      allow(described_class).to receive(:detect).and_return(:vim)
      allow(described_class).to receive(:system)
        .with("which", "nvim", out: File::NULL, err: File::NULL)
        .and_return(true)

      described_class.open("file.md", 5)

      expect(described_class).to have_received(:spawn)
        .with("nvim", "+5", "file.md", %i[out err] => File::NULL)
    end

    it "generates correct command for vim when nvim not available" do
      allow(described_class).to receive(:detect).and_return(:vim)
      allow(described_class).to receive(:system)
        .with("which", "nvim", out: File::NULL, err: File::NULL)
        .and_return(false)

      described_class.open("file.md", 5)

      expect(described_class).to have_received(:spawn)
        .with("vim", "+5", "file.md", %i[out err] => File::NULL)
    end

    it "generates correct command for Emacs" do
      allow(described_class).to receive(:detect).and_return(:emacs)

      described_class.open("file.md", 5)

      expect(described_class).to have_received(:spawn)
        .with("emacs", "+5", "file.md", %i[out err] => File::NULL)
    end
  end
end
