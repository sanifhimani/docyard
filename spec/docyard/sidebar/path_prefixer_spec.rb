# frozen_string_literal: true

RSpec.describe Docyard::Sidebar::PathPrefixer do
  describe "#prefix" do
    context "with empty prefix" do
      it "returns tree unchanged" do
        tree = [{ path: "/intro", title: "Intro", children: [] }]
        prefixer = described_class.new(tree, "")

        expect(prefixer.prefix).to eq(tree)
      end
    end

    context "with prefix" do
      it "prefixes simple paths" do
        tree = [{ path: "/intro", title: "Intro", children: [] }]
        prefixer = described_class.new(tree, "/guide")

        result = prefixer.prefix

        expect(result[0][:path]).to eq("/guide/intro")
      end

      it "handles root path without trailing slash" do
        tree = [{ path: "/", title: "Overview", children: [] }]
        prefixer = described_class.new(tree, "/guide")

        result = prefixer.prefix

        expect(result[0][:path]).to eq("/guide")
      end

      it "preserves external URLs unchanged" do
        tree = [{ path: "https://github.com/example", title: "GitHub", children: [] }]
        prefixer = described_class.new(tree, "/guide")

        result = prefixer.prefix

        expect(result[0][:path]).to eq("https://github.com/example")
      end

      it "handles nil paths" do
        tree = [{ path: nil, title: "Section Header", children: [] }]
        prefixer = described_class.new(tree, "/guide")

        result = prefixer.prefix

        expect(result[0][:path]).to be_nil
      end

      it "recursively prefixes children", :aggregate_failures do
        tree = [{
          path: "/parent",
          title: "Parent",
          children: [
            { path: "/child", title: "Child", children: [] }
          ]
        }]
        prefixer = described_class.new(tree, "/guide")

        result = prefixer.prefix

        expect(result[0][:path]).to eq("/guide/parent")
        expect(result[0][:children][0][:path]).to eq("/guide/child")
      end

      it "preserves other item properties", :aggregate_failures do
        tree = [{
          path: "/intro",
          title: "Introduction",
          icon: "book",
          active: true,
          children: []
        }]
        prefixer = described_class.new(tree, "/guide")

        result = prefixer.prefix

        expect(result[0][:title]).to eq("Introduction")
        expect(result[0][:icon]).to eq("book")
        expect(result[0][:active]).to be true
      end
    end
  end
end
