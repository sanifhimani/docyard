# frozen_string_literal: true

RSpec.describe Docyard::Sidebar::Item do
  describe "#initialize" do
    it "sets basic attributes", :aggregate_failures do
      item = described_class.new(slug: "test", text: "Test Item", path: "/test")

      expect(item.slug).to eq("test")
      expect(item.text).to eq("Test Item")
      expect(item.path).to eq("/test")
    end

    it "sets optional attributes", :aggregate_failures do
      item = described_class.new(icon: "rocket-launch", active: true, type: :directory)

      expect(item.icon).to eq("rocket-launch")
      expect(item.active).to be true
      expect(item.type).to eq(:directory)
    end

    it "sets link attributes", :aggregate_failures do
      item = described_class.new(target: "_blank", collapsed: true, items: [])

      expect(item.target).to eq("_blank")
      expect(item.collapsed).to be true
      expect(item.children).to eq([])
    end

    it "defaults to sensible values", :aggregate_failures do
      item = described_class.new(slug: "simple")

      expect(item.icon).to be_nil
      expect(item.active).to be false
      expect(item.type).to eq(:file)
      expect(item.target).to eq("_self")
      expect(item.collapsed).to be false
    end
  end

  describe "#external?" do
    it "returns true for http links" do
      item = described_class.new(slug: "test", text: "Test", path: "http://example.com")

      expect(item.external?).to be true
    end

    it "returns true for https links" do
      item = described_class.new(slug: "test", text: "Test", path: "https://example.com")

      expect(item.external?).to be true
    end

    it "returns false for internal links" do
      item = described_class.new(slug: "test", text: "Test", path: "/internal")

      expect(item.external?).to be false
    end

    it "returns false when path is nil" do
      item = described_class.new(slug: "test", text: "Test", path: nil)

      expect(item.external?).to be false
    end
  end

  describe "#to_h" do
    it "includes basic attributes in hash", :aggregate_failures do
      item = described_class.new(slug: "parent", text: "Parent", path: "/parent")
      hash = item.to_h

      expect(hash[:title]).to eq("Parent")
      expect(hash[:path]).to eq("/parent")
    end

    it "includes optional attributes in hash", :aggregate_failures do
      item = described_class.new(icon: "star", active: true, type: :directory)
      hash = item.to_h

      expect(hash[:icon]).to eq("star")
      expect(hash[:active]).to be true
      expect(hash[:type]).to eq(:directory)
    end

    it "includes link attributes in hash", :aggregate_failures do
      item = described_class.new(target: "_self", collapsed: true)
      hash = item.to_h

      expect(hash[:target]).to eq("_self")
      expect(hash[:collapsed]).to be true
    end

    it "includes collapsible status", :aggregate_failures do
      # With section: false, children make it collapsible
      item_with_children = described_class.new(items: [described_class.new(text: "Child")], section: false)
      # Sections with children are not collapsible
      section_with_children = described_class.new(items: [described_class.new(text: "Child")], section: true)
      item_without = described_class.new(items: [])

      expect(item_with_children.to_h[:collapsible]).to be true
      expect(section_with_children.to_h[:collapsible]).to be false
      expect(item_without.to_h[:collapsible]).to be false
    end

    it "recursively converts children to hash", :aggregate_failures do
      child = described_class.new(slug: "child", text: "Child", path: "/child")
      item = described_class.new(items: [child])
      hash = item.to_h

      expect(hash[:children]).to be_an(Array)
      expect(hash[:children].first[:title]).to eq("Child")
    end
  end
end
