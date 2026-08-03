# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Content::Preformatted do
  it 'stores lines as an array of strings' do
    pref = described_class.new(['line 1', 'line 2'])
    expect(pref.lines).to eq(['line 1', 'line 2'])
  end

  it 'joins lines with newlines for text' do
    pref = described_class.new(['a', 'b', 'c'])
    expect(pref.text).to eq("a\nb\nc")
  end

  it 'defaults style_id to :preformatted' do
    pref = described_class.new(['x'])
    expect(pref.style_id).to eq(:preformatted)
  end

  it 'accepts a language hint' do
    pref = described_class.new(['x = 1'], language: 'ruby')
    expect(pref.language).to eq('ruby')
  end

  it 'is empty when all lines are empty' do
    expect(described_class.new(['', ''])).to be_empty
  end

  it 'is not empty when any line has content' do
    expect(described_class.new(['', 'x'])).not_to be_empty
  end

  it 'compares by value' do
    a = described_class.new(['x'], language: 'rb')
    b = described_class.new(['x'], language: 'rb')
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is frozen' do
    expect(described_class.new(['x'])).to be_frozen
  end
end
