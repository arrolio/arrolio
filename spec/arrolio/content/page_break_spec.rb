# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Content::PageBreak do
  it 'creates with no arguments' do
    pb = described_class.new
    expect(pb.id).to be_nil
  end

  it 'accepts an optional id' do
    pb = described_class.new(id: 'break-1')
    expect(pb.id).to eq('break-1')
  end

  it 'compares by value' do
    a = described_class.new(id: 'x')
    b = described_class.new(id: 'x')
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is frozen' do
    expect(described_class.new).to be_frozen
  end
end
