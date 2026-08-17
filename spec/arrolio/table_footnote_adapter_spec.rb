# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::GenericAdapter do
  describe 'table cell footnotes' do
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
          'table_cell' => ['td', 'th'],
          'footnote_marker' => 'fn',
          'paragraph' => 'p',
          'id_attribute' => 'id'
        },
        'sections' => { 'container' => 'sections' }
      }
    end

    let(:adapter) { described_class.new(rules: rules) }

    let(:xml) do
      '<root><bibdata/><sections><clause>' \
        '<table id="tbl-1">' \
        '<thead><tr><th>Head<pLC/>text' \
        '<fn reference="a" id="fn-1"><p>p equals 0.7 applies here</p></fn>' \
        '</th></tr></thead>' \
        '<tbody><tr><td>cell</td></tr></tbody>' \
        '</table>' \
        '</clause></sections></root>'
    end

    it 'keeps only the marker in the cell and lifts the body to the table' do
      doc = adapter.convert(xml)
      table = doc.sections.first.children.find { |c| c.is_a?(Arrolio::Content::Table) }
      expect(table.footnotes.length).to eq(1)
      expect(table.footnotes.first.marker).to eq('a')
      expect(table.footnotes.first.body_text).to include('p equals 0.7')
      header_cell = table.header.first.cells.first
      expect(header_cell.text).not_to include('applies here')
      expect(header_cell.text).to include('a')
    end

    it 'emits the marker as a superscript run' do
      doc = adapter.convert(xml)
      table = doc.sections.first.children.find { |c| c.is_a?(Arrolio::Content::Table) }
      marker = table.header.first.cells.first.content.first.inline_runs.find { |r| r.text == 'a' }
      expect(marker.baseline_shift).to eq(Arrolio::Content::InlineRun::BASELINE_SUP)
      expect(marker.font_size_scale).to be < 1.0
    end

    it 'parses align and valign from the cell' do
      xml = '<root><bibdata/><sections><clause>' \
            '<table id="tbl-2"><thead/><tbody>' \
            '<tr><td align="center" valign="middle">x</td></tr>' \
            '</tbody></table></clause></sections></root>'
      doc = adapter.convert(xml)
      table = doc.sections.first.children.find { |c| c.is_a?(Arrolio::Content::Table) }
      cell = table.body.first.cells.first
      expect(cell.align).to eq(:center)
      expect(cell.valign).to eq(:middle)
    end
  end

  describe 'inline SVG viewBox sizing' do
    it 'converts SVG pixels to PDF points (72/96)' do
      rules = {
        'metadata' => { 'root' => 'bibdata', 'fields' => {} },
        'element_mapping' => {
          'clause' => { 'content_type' => 'section' },
          'figure' => { 'content_type' => 'figure' }
        },
        'selectors' => {
          'figure_image' => 'image',
          'figure_caption' => 'fmt-name',
          'id_attribute' => 'id'
        },
        'sections' => { 'container' => 'sections' }
      }
      svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 459.12 285.96"><text>x</text></svg>'
      xml = '<root><bibdata/><sections><clause>' \
            '<figure id="fig-1"><image>' + svg + '</image>' \
                                                 '<name>Figure 1 — t</name></figure>' \
                                                 '</clause></sections></root>'
      doc = described_class.new(rules: rules).convert(xml)
      figure = doc.sections.first.children.find { |c| c.is_a?(Arrolio::Content::FigureGroup) }
      expect(figure.image.width).to be_within(0.01).of(459.12 * 72.0 / 96.0)
      expect(figure.image.height).to be_within(0.01).of(285.96 * 72.0 / 96.0)
    end
  end
end
