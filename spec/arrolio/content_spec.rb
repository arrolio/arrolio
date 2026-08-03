# frozen_string_literal: true

require 'arrolio'

RSpec.describe Arrolio::Content::Document do
  it 'builds via DSL with nested sections, paragraphs, and lists' do
    doc = described_class.build do |d|
      d.section 'Introduction', number: '1' do |s|
        s.paragraph 'Hello, world.'
        s.list [{ content: [Arrolio::Content::Paragraph.new(
          [Arrolio::Content::InlineRun.new('first')]
        )] }]
      end
    end
    expect(doc.sections.length).to eq(1)
    intro = doc.sections.first
    expect(intro.title).to eq('Introduction')
    expect(intro.number).to eq('1')
    expect(intro.children.length).to eq(2)
    expect(intro.children[0]).to be_a(Arrolio::Content::Paragraph)
    expect(intro.children[0].text).to eq('Hello, world.')
    expect(intro.children[1]).to be_a(Arrolio::Content::List)
  end
end

RSpec.describe Arrolio::Content::InlineRun do
  it 'compares by text + style_id + href' do
    a = described_class.new('hi', style_id: :strong)
    b = described_class.new('hi', style_id: :strong)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it 'is frozen' do
    expect(described_class.new('hi')).to be_frozen
  end
end

RSpec.describe Arrolio::Content::Table do
  it 'coerces plain Arrays into Row and Cell instances' do
    table = described_class.new(
      header: [['h1', 'h2']],
      body: [['a', 'b']]
    )
    expect(table.header.first).to be_a(Arrolio::Content::Table::Row)
    expect(table.header.first.cells.first).to be_a(Arrolio::Content::Table::Cell)
    expect(table.body.first.cells.map(&:text)).to eq(['a', 'b'])
  end
end
