# frozen_string_literal: true

RSpec.describe Docyard::Sidebar::TreeFilter do
  describe "#filter" do
    it "keeps items matching the tab path exactly", :aggregate_failures do
      tree = [
        { path: "/guide", title: "Guide", children: [] },
        { path: "/api", title: "API", children: [] }
      ]
      filter = described_class.new(tree, "/guide")

      result = filter.filter

      expect(result.length).to eq(1)
      expect(result[0][:path]).to eq("/guide")
    end

    it "keeps items under the tab path", :aggregate_failures do
      tree = [
        { path: "/guide/intro", title: "Intro", children: [] },
        { path: "/guide/setup", title: "Setup", children: [] },
        { path: "/api/reference", title: "Reference", children: [] }
      ]
      filter = described_class.new(tree, "/guide")

      result = filter.filter

      expect(result.length).to eq(2)
      expect(result.map { |i| i[:path] }).to eq(["/guide/intro", "/guide/setup"])
    end

    it "keeps external links at leaf level" do
      tree = [
        { path: "/guide/intro", title: "Intro", children: [] },
        { path: "https://github.com", title: "GitHub", type: :external, children: [] }
      ]
      filter = described_class.new(tree, "/guide")

      result = filter.filter

      expect(result.length).to eq(2)
    end

    it "filters children recursively", :aggregate_failures do
      tree = [{
        path: "/docs",
        title: "Docs",
        children: [
          { path: "/guide/intro", title: "Guide Intro", children: [] },
          { path: "/api/ref", title: "API Ref", children: [] }
        ]
      }]
      filter = described_class.new(tree, "/guide")

      result = filter.filter

      expect(result.length).to eq(1)
      expect(result[0][:children].length).to eq(1)
      expect(result[0][:children][0][:path]).to eq("/guide/intro")
    end

    it "removes parent if no matching children" do
      tree = [{
        path: "/other",
        title: "Other",
        children: [
          { path: "/other/stuff", title: "Stuff", children: [] }
        ]
      }]
      filter = described_class.new(tree, "/guide")

      result = filter.filter

      expect(result).to be_empty
    end

    it "handles trailing slashes in paths" do
      tree = [
        { path: "/guide/", title: "Guide", children: [] }
      ]
      filter = described_class.new(tree, "/guide")

      result = filter.filter

      expect(result.length).to eq(1)
    end

    it "handles http:// external links" do
      tree = [
        { path: "http://example.com", title: "Example", children: [] }
      ]
      filter = described_class.new(tree, "/guide")

      result = filter.filter

      expect(result.length).to eq(1)
    end

    it "handles nil paths gracefully" do
      tree = [
        { path: nil, title: "Section", children: [] }
      ]
      filter = described_class.new(tree, "/guide")

      result = filter.filter

      expect(result).to be_empty
    end
  end
end
