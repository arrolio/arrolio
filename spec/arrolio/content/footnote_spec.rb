# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Content::Footnote do
  let(:body) do
    [Arrolio::Content::Paragraph.new(
    [Arrolio::Content::InlineRun.new('A note about load cells.')]
  )]
  end

  it 'carries marker + body' do
    fn = described_class.new(marker: '1', body: body)
    expect(fn.marker).to eq('1')
    expect(fn.body).to eq(body)
  end

  it 'extracts body text from paragraphs' do
    fn = described_class.new(marker: '1', body: body)
    expect(fn.body_text).to eq('A note about load cells.')
  end

  it 'defaults style_id to :footnote' do
    fn = described_class.new(marker: '*', body: body)
    expect(fn.style_id).to eq(:footnote)
  end

  it 'is empty when both marker and body are empty' do
    fn = described_class.new(marker: '', body: [])
    expect(fn).to be_empty
  end

  it 'compares by value' do
    a = described_class.new(marker: '1', body: body, id: 'fn1')
    b = described_class.new(marker: '1', body: body, id: 'fn1')
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is frozen' do
    expect(described_class.new(marker: '1', body: body)).to be_frozen
  end
end
