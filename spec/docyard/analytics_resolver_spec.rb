# frozen_string_literal: true

RSpec.describe Docyard::AnalyticsResolver do
  let(:test_class) do
    Class.new do
      include Docyard::AnalyticsResolver

      attr_accessor :config
    end
  end

  let(:instance) { test_class.new }
  let(:analytics_struct) { Struct.new(:google, :plausible, :fathom, :script) }
  let(:config_struct) { Struct.new(:analytics) }

  describe "#analytics_options" do
    context "when google analytics is configured" do
      before do
        analytics = analytics_struct.new("G-XXXXXXX", nil, nil, nil)
        instance.config = config_struct.new(analytics)
      end

      it "returns google analytics ID and has_analytics true", :aggregate_failures do
        result = instance.analytics_options

        expect(result[:analytics_google]).to eq("G-XXXXXXX")
        expect(result[:has_analytics]).to be true
      end
    end

    context "when plausible is configured" do
      before do
        analytics = analytics_struct.new(nil, "example.com", nil, nil)
        instance.config = config_struct.new(analytics)
      end

      it "returns plausible domain and has_analytics true", :aggregate_failures do
        result = instance.analytics_options

        expect(result[:analytics_plausible]).to eq("example.com")
        expect(result[:has_analytics]).to be true
      end
    end

    context "when fathom is configured" do
      before do
        analytics = analytics_struct.new(nil, nil, "ABCDEFGH", nil)
        instance.config = config_struct.new(analytics)
      end

      it "returns fathom site ID and has_analytics true", :aggregate_failures do
        result = instance.analytics_options

        expect(result[:analytics_fathom]).to eq("ABCDEFGH")
        expect(result[:has_analytics]).to be true
      end
    end

    context "when custom script is configured" do
      before do
        analytics = analytics_struct.new(nil, nil, nil, "<script>custom</script>")
        instance.config = config_struct.new(analytics)
      end

      it "returns custom script and has_analytics true", :aggregate_failures do
        result = instance.analytics_options

        expect(result[:analytics_script]).to eq("<script>custom</script>")
        expect(result[:has_analytics]).to be true
      end
    end

    context "when no analytics are configured" do
      before do
        analytics = analytics_struct.new(nil, nil, nil, nil)
        instance.config = config_struct.new(analytics)
      end

      it "returns has_analytics false" do
        result = instance.analytics_options

        expect(result[:has_analytics]).to be false
      end
    end

    context "when analytics values are empty strings" do
      before do
        analytics = analytics_struct.new("", "  ", "", nil)
        instance.config = config_struct.new(analytics)
      end

      it "returns has_analytics false for empty/whitespace strings" do
        result = instance.analytics_options

        expect(result[:has_analytics]).to be false
      end
    end

    context "when multiple analytics are configured" do
      before do
        analytics = analytics_struct.new("G-XXXXXXX", "example.com", nil, nil)
        instance.config = config_struct.new(analytics)
      end

      it "returns all configured values and has_analytics true", :aggregate_failures do
        result = instance.analytics_options

        expect(result[:analytics_google]).to eq("G-XXXXXXX")
        expect(result[:analytics_plausible]).to eq("example.com")
        expect(result[:has_analytics]).to be true
      end
    end
  end
end
