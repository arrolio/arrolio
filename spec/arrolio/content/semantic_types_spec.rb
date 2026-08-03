# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Content::Note do
  let(:body) { [Arrolio::Content::Paragraph.new([Arrolio::Content::InlineRun.new('text')])] }

  it 'carries label + body + style_id' do
    note = described_class.new(label: 'NOTE 1', body: body)
    expect(note.label).to eq('NOTE 1')
    expect(note.body).to eq(body)
    expect(note.style_id).to eq(:note)
  end

  it 'joins body Paragraph text via body_text' do
    note = described_class.new(body: body)
    expect(note.body_text).to eq('text')
  end

  it 'defaults label to empty string' do
    expect(described_class.new(body: body).label).to eq('')
  end

  it 'is frozen' do
    expect(described_class.new(body: body)).to be_frozen
  end

  it 'compares by value' do
    a = described_class.new(label: 'X', body: body)
    b = described_class.new(label: 'X', body: body)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is empty when all body Paragraphs are empty' do
    empty_body = [Arrolio::Content::Paragraph.new([])]
    expect(described_class.new(body: empty_body)).to be_empty
  end
end

RSpec.describe Arrolio::Content::Example do
  let(:body) { [Arrolio::Content::Paragraph.new([Arrolio::Content::InlineRun.new('ex')])] }

  it 'defaults style_id to :example' do
    expect(described_class.new(body: body).style_id).to eq(:example)
  end

  it 'is frozen and compares by value' do
    a = described_class.new(label: 'EX 1', body: body)
    b = described_class.new(label: 'EX 1', body: body)
    expect(a).to eq(b)
    expect(a).to be_frozen
  end
end

RSpec.describe Arrolio::Content::TermEntry do
  it 'carries number, preferred, definition, source' do
    entry = described_class.new(
      number: '3.1.1',
      preferred: 'calibration',
      source: '[ISO 9000]'
    )
    expect(entry.number).to eq('3.1.1')
    expect(entry.preferred).to eq('calibration')
    expect(entry.source).to eq('[ISO 9000]')
    expect(entry.style_id).to eq(:term)
  end

  it 'is empty when all fields are nil' do
    expect(described_class.new).to be_empty
  end

  it 'is frozen and compares by value' do
    a = described_class.new(number: '1', preferred: 'x')
    b = described_class.new(number: '1', preferred: 'x')
    expect(a).to eq(b)
    expect(a).to be_frozen
  end
end

RSpec.describe Arrolio::Content::FigureGroup do
  let(:image) { Arrolio::Content::Image.new('img.png') }
  let(:caption) { Arrolio::Content::Paragraph.new([Arrolio::Content::InlineRun.new('Fig. 1')]) }

  it 'carries image and caption' do
    fg = described_class.new(image: image, caption: caption)
    expect(fg.image).to eq(image)
    expect(fg.caption).to eq(caption)
    expect(fg.style_id).to eq(:figure)
  end

  it 'is frozen and compares by value' do
    a = described_class.new(image: image, caption: caption)
    b = described_class.new(image: image, caption: caption)
    expect(a).to eq(b)
    expect(a).to be_frozen
  end
end

RSpec.describe Arrolio::Content::BibliographyItem do
  let(:ref) { Arrolio::Content::Paragraph.new([Arrolio::Content::InlineRun.new('Smith 2020')]) }

  it 'carries tag and formattedref' do
    item = described_class.new(tag: '[Smith2020]', formattedref: ref)
    expect(item.tag).to eq('[Smith2020]')
    expect(item.formattedref).to eq(ref)
    expect(item.text).to eq('Smith 2020')
    expect(item.style_id).to eq(:bibitem)
  end

  it 'is frozen and compares by value' do
    a = described_class.new(tag: '[X]', formattedref: ref)
    b = described_class.new(tag: '[X]', formattedref: ref)
    expect(a).to eq(b)
    expect(a).to be_frozen
  end
end
