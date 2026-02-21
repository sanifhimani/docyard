# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::VariablesProcessor do
  let(:variables) { { "version" => "2.5.0", "repo" => "github.com/user/project", "min_ruby" => "3.0" } }
  let(:context) { { config: { "variables" => variables } } }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with single variable" do
      it "replaces the variable with its value" do
        result = processor.preprocess("Install version {{ version }}.")

        expect(result).to eq("Install version 2.5.0.")
      end
    end

    context "with multiple different variables" do
      it "replaces all variables" do
        result = processor.preprocess("Version {{ version }} from {{ repo }}.")

        expect(result).to eq("Version 2.5.0 from github.com/user/project.")
      end
    end

    context "with multiple occurrences of the same variable" do
      it "replaces every occurrence" do
        result = processor.preprocess("{{ version }} and {{ version }} again.")

        expect(result).to eq("2.5.0 and 2.5.0 again.")
      end
    end

    context "with no variables in config" do
      let(:context) { { config: { "variables" => {} } } }

      it "returns content unchanged" do
        content = "No {{ replacement }} here."
        result = processor.preprocess(content)

        expect(result).to eq(content)
      end
    end

    context "with nil variables in config" do
      let(:context) { { config: {} } }

      it "returns content unchanged" do
        content = "No {{ replacement }} here."
        result = processor.preprocess(content)

        expect(result).to eq(content)
      end
    end

    context "with undefined variable" do
      it "leaves the placeholder as-is" do
        result = processor.preprocess("Unknown {{ nonexistent }} variable.")

        expect(result).to eq("Unknown {{ nonexistent }} variable.")
      end
    end

    context "with whitespace flexibility" do
      it "handles no spaces" do
        result = processor.preprocess("{{version}}")

        expect(result).to eq("2.5.0")
      end

      it "handles single spaces" do
        result = processor.preprocess("{{ version }}")

        expect(result).to eq("2.5.0")
      end

      it "handles extra spaces" do
        result = processor.preprocess("{{  version  }}")

        expect(result).to eq("2.5.0")
      end
    end

    context "with fenced code blocks" do
      it "does not replace variables inside code blocks", :aggregate_failures do
        content = <<~MARKDOWN
          Install {{ version }}.

          ```yaml
          version: {{ version }}
          ```

          Done.
        MARKDOWN

        result = processor.preprocess(content)

        expect(result).to include("Install 2.5.0.")
        expect(result).to include("version: {{ version }}\n```")
        expect(result).to include("Done.")
      end

      it "does not replace variables inside tilde code blocks", :aggregate_failures do
        content = <<~MARKDOWN
          Install {{ version }}.

          ~~~
          {{ version }}
          ~~~
        MARKDOWN

        result = processor.preprocess(content)

        expect(result).to include("Install 2.5.0.")
        expect(result).to include("{{ version }}\n~~~")
      end
    end

    context "with -vars suffix on code blocks" do
      it "replaces variables in a code block with -vars suffix", :aggregate_failures do
        content = <<~MARKDOWN
          ```bash-vars
          gem install docyard -v {{ version }}
          ```
        MARKDOWN

        result = processor.preprocess(content)

        expect(result).to include("gem install docyard -v 2.5.0")
        expect(result).not_to include("{{ version }}")
      end

      it "strips the -vars suffix from the language", :aggregate_failures do
        content = <<~MARKDOWN
          ```yaml-vars
          version: {{ version }}
          ```
        MARKDOWN

        result = processor.preprocess(content)

        expect(result).to include("```yaml\n")
        expect(result).not_to include("yaml-vars")
      end

      it "works with tilde fences", :aggregate_failures do
        content = <<~MARKDOWN
          ~~~toml-vars
          version = "{{ version }}"
          ~~~
        MARKDOWN

        result = processor.preprocess(content)

        expect(result).to include("~~~toml\n")
        expect(result).to include('version = "2.5.0"')
      end

      it "leaves regular code blocks untouched alongside -vars blocks", :aggregate_failures do
        content = <<~MARKDOWN
          ```bash-vars
          echo {{ version }}
          ```

          ```bash
          echo {{ version }}
          ```
        MARKDOWN

        result = processor.preprocess(content)

        expect(result).to include("echo 2.5.0")
        expect(result).to include("echo {{ version }}")
      end
    end

    context "with nested dot notation" do
      let(:variables) do
        {
          "repo" => { "url" => "github.com/user/project", "branch" => "main" },
          "version" => "2.5.0"
        }
      end

      it "resolves nested values" do
        result = processor.preprocess("Clone {{ repo.url }} on {{ repo.branch }}.")

        expect(result).to eq("Clone github.com/user/project on main.")
      end

      it "leaves deeply undefined paths as-is" do
        result = processor.preprocess("{{ repo.nonexistent }}")

        expect(result).to eq("{{ repo.nonexistent }}")
      end

      it "leaves paths through non-hash values as-is" do
        result = processor.preprocess("{{ version.patch }}")

        expect(result).to eq("{{ version.patch }}")
      end
    end

    context "with numeric and boolean values" do
      let(:variables) { { "port" => 8080, "debug" => true, "ratio" => 3.14 } }

      it "converts values to strings" do
        result = processor.preprocess("Port {{ port }}, debug {{ debug }}, ratio {{ ratio }}.")

        expect(result).to eq("Port 8080, debug true, ratio 3.14.")
      end
    end

    context "with empty string value" do
      let(:variables) { { "empty" => "" } }

      it "replaces with empty string" do
        result = processor.preprocess("Value: {{ empty }}.")

        expect(result).to eq("Value: .")
      end
    end

    context "with surrounding markdown structure" do
      it "preserves headings, lists, and formatting", :aggregate_failures do
        content = <<~MARKDOWN
          # Install v{{ version }}

          - Download from {{ repo }}
          - Requires Ruby {{ min_ruby }}

          **Current:** {{ version }}
        MARKDOWN

        result = processor.preprocess(content)

        expect(result).to include("# Install v2.5.0")
        expect(result).to include("- Download from github.com/user/project")
        expect(result).to include("- Requires Ruby 3.0")
        expect(result).to include("**Current:** 2.5.0")
      end
    end
  end
end
