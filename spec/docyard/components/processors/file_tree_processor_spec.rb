# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::FileTreeProcessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with basic file tree" do
      it "wraps content in docyard-filetree container", :aggregate_failures do
        content = "```filetree\nfile.txt\n```"
        result = processor.preprocess(content)

        expect(result).to include('<div class="docyard-filetree"')
        expect(result).to include("</div>")
      end

      it "creates list structure", :aggregate_failures do
        content = "```filetree\nfile.txt\n```"
        result = processor.preprocess(content)

        expect(result).to include('<ul class="docyard-filetree__list">')
        expect(result).to include('<li class="docyard-filetree__item')
      end

      it "renders file with file icon", :aggregate_failures do
        content = "```filetree\nindex.js\n```"
        result = processor.preprocess(content)

        expect(result).to include("ph-file-text")
        expect(result).to include("docyard-filetree__item--file")
      end
    end

    context "with folders" do
      it "detects folders by trailing slash", :aggregate_failures do
        content = "```filetree\nsrc/\n```"
        result = processor.preprocess(content)

        expect(result).to include("ph-folder-open")
        expect(result).to include("docyard-filetree__item--folder")
      end

      it "removes trailing slash from displayed name", :aggregate_failures do
        content = "```filetree\nsrc/\n```"
        result = processor.preprocess(content)

        expect(result).to include('class="docyard-filetree__name">src</span>')
        expect(result).not_to include(">src/</span>")
      end
    end

    context "with nested structure" do
      it "creates nested lists for indented items", :aggregate_failures do
        content = "```filetree\nsrc/\n  index.js\n```"
        result = processor.preprocess(content)

        expect(result.scan("docyard-filetree__list").count).to be >= 2
        expect(result).to include("src")
        expect(result).to include("index.js")
      end

      it "handles multiple nesting levels", :aggregate_failures do
        content = "```filetree\nsrc/\n  components/\n    Button.jsx\n```"
        result = processor.preprocess(content)

        expect(result).to include("src")
        expect(result).to include("components")
        expect(result).to include("Button.jsx")
      end

      it "handles siblings at same level", :aggregate_failures do
        content = "```filetree\nsrc/\n  index.js\n  app.js\n```"
        result = processor.preprocess(content)

        expect(result).to include("index.js")
        expect(result).to include("app.js")
      end
    end

    context "with comments" do
      it "extracts comment after # marker", :aggregate_failures do
        content = "```filetree\nconfig.js # Main configuration\n```"
        result = processor.preprocess(content)

        expect(result).to include("docyard-filetree__comment")
        expect(result).to include("Main configuration")
      end

      it "separates name from comment", :aggregate_failures do
        content = "```filetree\nconfig.js # Config file\n```"
        result = processor.preprocess(content)

        expect(result).to include('class="docyard-filetree__name">config.js</span>')
        expect(result).to include('class="docyard-filetree__comment">Config file</span>')
      end
    end

    context "with highlighted items" do
      it "adds highlighted class for items ending with *" do
        content = "```filetree\nimportant.js *\n```"
        result = processor.preprocess(content)

        expect(result).to include("docyard-filetree__item--highlighted")
      end

      it "removes * from displayed name", :aggregate_failures do
        content = "```filetree\nimportant.js *\n```"
        result = processor.preprocess(content)

        expect(result).to include('class="docyard-filetree__name">important.js</span>')
        expect(result).not_to include(">important.js *</span>")
      end

      it "combines highlighting with comments", :aggregate_failures do
        content = "```filetree\napp.js # Entry point *\n```"
        result = processor.preprocess(content)

        expect(result).to include("docyard-filetree__item--highlighted")
        expect(result).to include("Entry point")
      end
    end

    context "with complex structure" do
      it "handles real-world project structure", :aggregate_failures do
        content = "```filetree\nproject/\n  src/\n    Button.jsx *\n    helpers.js # Utils\n  package.json\n```"
        result = processor.preprocess(content)

        expect(result).to include("project")
        expect(result).to include("Button.jsx")
        expect(result).to include("docyard-filetree__item--highlighted")
        expect(result).to include("Utils")
        expect(result).to include("package.json")
      end
    end

    context "with empty content" do
      it "handles empty file tree" do
        content = "```filetree\n```"
        result = processor.preprocess(content)

        expect(result).to include("docyard-filetree")
      end

      it "skips empty lines", :aggregate_failures do
        content = "```filetree\nfile.txt\n\nanother.txt\n```"
        result = processor.preprocess(content)

        expect(result).to include("file.txt")
        expect(result).to include("another.txt")
      end
    end

    context "with special characters" do
      it "escapes HTML in file names", :aggregate_failures do
        content = "```filetree\n<script>.js\n```"
        result = processor.preprocess(content)

        expect(result).to include("&lt;script&gt;.js")
        expect(result).not_to include("<script>.js</span>")
      end

      it "escapes HTML in comments" do
        content = "```filetree\nfile.js # Contains <b>bold</b>\n```"
        result = processor.preprocess(content)

        expect(result).to include("&lt;b&gt;bold&lt;/b&gt;")
      end
    end

    context "with surrounding content" do
      it "preserves surrounding markdown", :aggregate_failures do
        content = "# Title\n\n```filetree\nsrc/\n```\n\nEnd"
        result = processor.preprocess(content)

        expect(result).to include("# Title")
        expect(result).to include("End")
        expect(result).to include("docyard-filetree")
      end
    end

    context "with multiple file trees" do
      it "processes all file trees", :aggregate_failures do
        content = "```filetree\nfrontend/\n```\n\n```filetree\nbackend/\n```"
        result = processor.preprocess(content)

        expect(result.scan("docyard-filetree\" markdown").count).to eq(2)
        expect(result).to include("frontend")
        expect(result).to include("backend")
      end
    end

    context "with markdown=0 attribute" do
      it "prevents markdown processing inside file tree" do
        content = "```filetree\nfile.txt\n```"
        result = processor.preprocess(content)

        expect(result).to include('markdown="0"')
      end
    end

    context "with code blocks" do
      it "does not process filetree syntax inside code blocks", :aggregate_failures do
        content = "```filetree\nsrc/\n```\n\n```markdown\n```filetree\nexample/\n```\n```"
        result = processor.preprocess(content)

        expect(result).to include('class="docyard-filetree"')
        expect(result.scan('class="docyard-filetree"').count).to eq(1)
        expect(result).to include("```filetree\nexample/")
      end
    end
  end
end
