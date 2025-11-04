# frozen_string_literal: true

RSpec.describe Docyard::VERSION do
  it "has a version number" do
    expect(Docyard::VERSION).not_to be_nil # rubocop:disable RSpec/DescribedClass
  end

  it "is a valid semantic version" do
    expect(Docyard::VERSION).to match(/\d+\.\d+\.\d+/) # rubocop:disable RSpec/DescribedClass
  end
end
