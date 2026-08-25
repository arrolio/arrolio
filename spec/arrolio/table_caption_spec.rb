# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::GenericAdapter do
  describe 'table caption extraction' do
  let(:rules) do
    {
      'metadata' => { 'root' => 'bibdata', 'fields' => {} },
      'element_mapping' => {
        'clause' => { 'content_type' => 'section' },
        'table' => { 'content_type' => 'table' }
      },
      'selectors' => {
        'figure_caption' => 'fmt-name',
        'figure_caption_fallback' => 'name',
        'table_header' => 'thead',
        'table_body' => 'tbody',
        'table_row' => 'tr',
        'table_cell' => ['td', 'th']
      },
      'sections' => { 'container' => 'sections' }
    }
  end

  let(:adapter) { described_class.new(rules: rules) }

  it 'extracts caption text from fmt-name inside table' do
    xml = '<root><bibdata/><sections><clause>' \
          '<table id="tbl-1">' \
          '<fmt-name>Table 1 — Test Caption</fmt-name>' \
          '<thead><tr><th>Col A</th></tr></thead>' \
          '<tbody><tr><td>data</td></tr></tbody>' \
          '</table>' \
          '</clause></sections></root>'
    doc = adapter.convert(xml)
    table = doc.sections.first.children.find { |c| c.is_a?(Arrolio::Content::Table) }
    expect(table).not_to be_nil
    caption = table.caption
    expect(caption).to be_a(Arrolio::Content::Paragraph)
    expect(caption.inline_runs.map(&:text).join).to eq('Table 1 — Test Caption')
  end

  it 'returns nil caption when table has no fmt-name' do
    xml = '<root><bibdata/><sections><clause>' \
          '<table id="tbl-2">' \
          '<thead><tr><th>Col A</th></tr></thead>' \
          '<tbody><tr><td>data</td></tr></tbody>' \
          '</table>' \
          '</clause></sections></root>'
    doc = adapter.convert(xml)
    table = doc.sections.first.children.find { |c| c.is_a?(Arrolio::Content::Table) }
    expect(table).not_to be_nil
    expect(table.caption).to be_nil
  end

  it 'collects caption runs through inline math (subscripts)' do
    xml = '<root><bibdata/><sections><clause>' \
          '<table id="tbl-3">' \
          '<fmt-name>Table 2 — Limits of <stem block="false" type="MathML">' \
          '<math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>n</mi>' \
          '<mtext>LC</mtext></msub></math><asciimath>n_("LC")</asciimath></stem> ' \
          'intervals</fmt-name>' \
          '<thead><tr><th>Col A</th></tr></thead>' \
          '<tbody><tr><td>data</td></tr></tbody>' \
          '</table>' \
          '</clause></sections></root>'
    doc = adapter.convert(xml)
    table = doc.sections.first.children.find { |c| c.is_a?(Arrolio::Content::Table) }
    text = table.caption.inline_runs.map(&:text).join
    expect(text).to include('n')
    expect(text).not_to include('asciimath')
    expect(text).not_to include('_(')
  end
  end
end
