# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Content::Heading do
  it 'carries level, number, title, id, style_id' do
    heading = described_class.new(
      level: 2, number: '3.5', title: 'Range and capacity', id: 'sec-3-5',
      style_id: :heading_2
    )
    expect(heading.level).to eq(2)
    expect(heading.number).to eq('3.5')
    expect(heading.title).to eq('Range and capacity')
    expect(heading.id).to eq('sec-3-5')
    expect(heading.style_id).to eq(:heading_2)
  end

  it 'defaults style_id to :heading_1' do
    heading = described_class.new(level: 1, title: 'Intro')
    expect(heading.style_id).to eq(:heading_1)
  end

  it 'is inline-header when number is present but title is empty' do
    heading = described_class.new(level: 2, number: '2.1', title: '')
    expect(heading.inline_header?).to be(true)
  end

  it 'is not inline-header when both number and title are present' do
    full = described_class.new(level: 1, number: '1', title: 'Introduction')
    expect(full.inline_header?).to be(false)
  end

  it 'is not inline-header when title is present but number is missing' do
    heading = described_class.new(level: 1, title: 'Standalone Title')
    expect(heading.inline_header?).to be(false)
  end

  it 'compares by value' do
    a = described_class.new(level: 1, number: '1', title: 'A')
    b = described_class.new(level: 1, number: '1', title: 'A')
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is frozen' do
    expect(described_class.new(level: 1, title: 'T')).to be_frozen
  end
end

RSpec.describe Arrolio::Content::Hyperlink do
  let(:runs) { [Arrolio::Content::InlineRun.new('click here')] }

  it 'carries runs + target URI' do
    link = described_class.new(runs, target: 'https://example.com')
    expect(link.runs).to eq(runs)
    expect(link.target).to eq('https://example.com')
    expect(link.external?).to be(true)
    expect(link.internal?).to be(false)
  end

  it 'marks internal links' do
    link = described_class.new(runs, target: 'sec-3-5', internal: true)
    expect(link.internal?).to be(true)
    expect(link.external?).to be(false)
  end

  it 'compares by value' do
    a = described_class.new(runs, target: 'https://x.com')
    b = described_class.new(runs, target: 'https://x.com')
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is frozen' do
    expect(described_class.new(runs, target: 'x')).to be_frozen
  end
end

RSpec.describe Arrolio::Content::Formula do
  it 'carries MathML + text fallback' do
    formula = described_class.new(mathml: '<msub><mi>D</mi></msub>', text_fallback: 'D_sub')
    expect(formula.mathml).to eq('<msub><mi>D</mi></msub>')
    expect(formula.text_fallback).to eq('D_sub')
  end

  it 'compares by value' do
    a = described_class.new(mathml: 'x', text_fallback: 'x')
    b = described_class.new(mathml: 'x', text_fallback: 'x')
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is frozen' do
    expect(described_class.new(mathml: '', text_fallback: '')).to be_frozen
  end
end
