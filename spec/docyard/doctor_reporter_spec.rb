# frozen_string_literal: true

RSpec.describe Docyard::DoctorReporter do
  let(:empty_results) do
    {
      broken_links: [],
      missing_images: [],
      orphan_pages: []
    }
  end

  describe "#exit_code" do
    it "returns 0 when no issues found" do
      reporter = described_class.new(empty_results)
      expect(reporter.exit_code).to eq(0)
    end

    it "returns 1 when broken links exist" do
      results = empty_results.merge(
        broken_links: [Docyard::Doctor::Issue.new(file: "a.md", line: 1, target: "/x")]
      )
      reporter = described_class.new(results)
      expect(reporter.exit_code).to eq(1)
    end

    it "returns 1 when missing images exist" do
      results = empty_results.merge(
        missing_images: [Docyard::Doctor::Issue.new(file: "a.md", line: 1, target: "/x.png")]
      )
      reporter = described_class.new(results)
      expect(reporter.exit_code).to eq(1)
    end

    it "returns 0 when only orphan pages exist (warnings)" do
      results = empty_results.merge(orphan_pages: [{ file: "orphan.md" }])
      reporter = described_class.new(results)
      expect(reporter.exit_code).to eq(0)
    end
  end

  describe "#print" do
    it "outputs 'No issues found' when clean" do
      reporter = described_class.new(empty_results)
      expect { reporter.print }.to output(/No issues found/).to_stdout
    end

    it "outputs broken links section when present" do
      results = empty_results.merge(
        broken_links: [Docyard::Doctor::Issue.new(file: "page.md", line: 5, target: "/missing")]
      )
      reporter = described_class.new(results)
      expect { reporter.print }.to output(/Broken Links/).to_stdout
    end

    it "outputs file location and target for broken links" do
      results = empty_results.merge(
        broken_links: [Docyard::Doctor::Issue.new(file: "page.md", line: 5, target: "/missing")]
      )
      reporter = described_class.new(results)
      expect { reporter.print }.to output(%r{page\.md:5.*/missing}).to_stdout
    end

    it "outputs missing images section when present" do
      results = empty_results.merge(
        missing_images: [Docyard::Doctor::Issue.new(file: "page.md", line: 3, target: "/img.png")]
      )
      reporter = described_class.new(results)
      expect { reporter.print }.to output(/Missing Images/).to_stdout
    end

    it "outputs orphan pages section when present" do
      results = empty_results.merge(orphan_pages: [{ file: "orphan.md" }])
      reporter = described_class.new(results)
      expect { reporter.print }.to output(/Orphan Pages/).to_stdout
    end

    it "outputs correct summary with singular error" do
      results = empty_results.merge(
        broken_links: [Docyard::Doctor::Issue.new(file: "a.md", line: 1, target: "/x")]
      )
      reporter = described_class.new(results)
      expect { reporter.print }.to output(/1 error/).to_stdout
    end

    it "outputs correct summary with plural errors" do
      results = empty_results.merge(
        broken_links: [
          Docyard::Doctor::Issue.new(file: "a.md", line: 1, target: "/x"),
          Docyard::Doctor::Issue.new(file: "b.md", line: 2, target: "/y")
        ]
      )
      reporter = described_class.new(results)
      expect { reporter.print }.to output(/2 errors/).to_stdout
    end

    it "outputs warnings count for orphan pages" do
      results = empty_results.merge(orphan_pages: [{ file: "a.md" }, { file: "b.md" }])
      reporter = described_class.new(results)
      expect { reporter.print }.to output(/2 warnings/).to_stdout
    end
  end
end
