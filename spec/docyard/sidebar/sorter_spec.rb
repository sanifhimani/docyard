# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Sidebar::Sorter do
  describe ".sort_by_order" do
    it "sorts items with order before items without order" do
      items = [
        { title: "Zebra", order: nil },
        { title: "Apple", order: 2 },
        { title: "Banana", order: 1 }
      ]

      result = described_class.sort_by_order(items)

      expect(result.map { |i| i[:title] }).to eq(%w[Banana Apple Zebra])
    end

    it "sorts items without order alphabetically" do
      items = [
        { title: "Zebra", order: nil },
        { title: "Apple", order: nil },
        { title: "Banana", order: nil }
      ]

      result = described_class.sort_by_order(items)

      expect(result.map { |i| i[:title] }).to eq(%w[Apple Banana Zebra])
    end

    it "sorts items with same order by title" do
      items = [
        { title: "Zebra", order: 1 },
        { title: "Apple", order: 1 }
      ]

      result = described_class.sort_by_order(items)

      expect(result.map { |i| i[:title] }).to eq(%w[Apple Zebra])
    end

    it "handles nil titles" do
      items = [
        { title: nil, order: 1 },
        { title: "Apple", order: 1 }
      ]

      result = described_class.sort_by_order(items)

      expect(result.map { |i| i[:title] }).to eq([nil, "Apple"])
    end
  end
end
