# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::LayoutSpec::ScaleLength do
  it 'resolves to base_value * scale_factor' do
    sl = described_class.new(base_value: 12.0, scale_factor: 0.8)
    expect(sl.resolved).to be_within(0.001).of(9.6)
  end

  it 'defaults scale_factor to 1.0' do
    sl = described_class.new(base_value: 10.0)
    expect(sl.resolved).to eq(10.0)
  end

  it 'creates a new scaled instance via with_scale' do
    sl = described_class.new(base_value: 12.0)
    scaled = sl.with_scale(0.5)
    expect(scaled.resolved).to eq(6.0)
    expect(scaled.base_value).to eq(12.0)
    expect(sl.resolved).to eq(12.0) # original unchanged
  end

  it 'compares by value' do
    a = described_class.new(base_value: 10.0, scale_factor: 0.5)
    b = described_class.new(base_value: 10.0, scale_factor: 0.5)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is frozen' do
    expect(described_class.new(base_value: 1.0)).to be_frozen
  end
end
