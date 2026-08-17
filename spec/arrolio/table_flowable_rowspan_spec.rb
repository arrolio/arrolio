# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Flowables::TableFlowable do
  let(:style) do
    Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 10)
  end

  def cell(text, colspan: 1, rowspan: 1, valign: nil)
    para = Arrolio::Content::Paragraph.new(
      [Arrolio::Content::InlineRun.new(text, style_id: :table_cell)]
    )
    Arrolio::Content::Table::Cell.new([para], colspan: colspan,
                                              rowspan: rowspan, valign: valign)
  end

  def row(*cells)
    Arrolio::Content::Table::Row.new(cells)
  end

  def build_table(header: [], body: [], footnotes: [])
    Arrolio::Content::Table.new(header: header, body: body, footnotes: footnotes)
  end

  def text_boxes(boxes)
    boxes.select { |b| b.kind == :text }
  end

  def rect_boxes(boxes)
    boxes.select { |b| b.kind == :rect }
  end

  describe 'rowspan' do
    it 'draws the spanning cell once with the combined row height' do
      table = build_table(
        header: [row(cell('H1'), cell('H2'))],
        body: [
          row(cell('a'), cell('span', rowspan: 2)),
          row(cell('b'))
        ]
      )
      tf = described_class.new(table, style: style, min_row_height: 20.0)
      boxes, = tf.emit(100.0, 500.0, 200.0, nil)
      rect_boxes(boxes).sort_by { |r| [-r.y - r.height, r.x] }
      # 3 rows (header + 2 body) -> one rect per placement; the
      # spanning cell covers both body rows.
      span = rect_boxes(boxes).max_by(&:height)
      expect(span.height).to be >= 40.0
      expect(span.y).to be < 500.0 - 20.0 - 20.0
      expect(rect_boxes(boxes).length).to eq(5)
    end

    it 'pushes a deficit into every spanned row when content overflows the span' do
      long = cell('word ' * 30, rowspan: 2)
      table = build_table(body: [row(cell('a'), long), row(cell('b'))])
      tf = described_class.new(table, style: style)
      expect(tf.height(120.0)).to be > 40.0
    end
  end

  describe 'table footnotes' do
    let(:footnote_body) do
      [Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('note body', style_id: :inline)]
      )]
    end

    let(:footnote) do
      Arrolio::Content::Footnote.new(marker: 'a', body: footnote_body)
    end

    it 'renders the footnote below the last row' do
      table = build_table(
        header: [row(cell('H'))],
        body: [row(cell('x'))],
        footnotes: [footnote]
      )
      tf = described_class.new(table, style: style, min_row_height: 20.0)
      boxes, consumed = tf.emit(100.0, 500.0, 200.0, nil)
      texts = text_boxes(boxes).map { |b| b.data[:lines].map { |l| l.placed_runs.map { |pr| pr.run.text }.join }.join }
      expect(texts.join).to include('a note body')
      expect(consumed).to be > 40.0
      fn_box = text_boxes(boxes).min_by(&:y)
      expect(fn_box.y).to be < 500.0 - 20.0
    end

    it 'counts the footnote block in height' do
      base = build_table(header: [row(cell('H'))], body: [row(cell('x'))])
      with_fn = build_table(header: [row(cell('H'))], body: [row(cell('x'))],
                            footnotes: [footnote])
      h0 = described_class.new(base, style: style, min_row_height: 20.0).height(200.0)
      h1 = described_class.new(with_fn, style: style, min_row_height: 20.0).height(200.0)
      expect(h1 - h0).to be > 10.0
    end
  end

  describe 'caption' do
    it 'emits the caption above the table and counts it in height' do
      table = build_table(header: [row(cell('H'))], body: [row(cell('x'))])
      tf = described_class.new(table, style: style, caption_text: 'Table 9 — Title',
                                      min_row_height: 20.0)
      boxes, consumed = tf.emit(100.0, 500.0, 200.0, nil)
      caption = text_boxes(boxes).max_by(&:y)
      caption_text = caption.data[:lines].map { |l| l.placed_runs.map { |pr| pr.run.text }.join }.join
      expect(caption_text).to eq('Table 9 — Title')
      expect(consumed).to be > 40.0
    end

    it 'emits the short caption with (continued) on continuation parts' do
      table = build_table(header: [row(cell('H'))], body: [row(cell('x'))])
      tf = described_class.new(table, style: style, caption_text: 'Table 9 — Title',
                                      continued: true, min_row_height: 20.0)
      boxes, = tf.emit(100.0, 500.0, 200.0, nil)
      caption = text_boxes(boxes).max_by(&:y)
      caption_text = caption.data[:lines].map { |l| l.placed_runs.map { |pr| pr.run.text }.join }.join
      expect(caption_text).to eq('Table 9 (continued)')
    end
  end

  describe '#do_split' do
    it 'keeps rowspan-welded rows together' do
      body = (1..8).map { |i| row(cell("r#{i}")) }
      body[0] = row(cell('r1a'), cell('r1b', rowspan: 2))
      body[1] = row(cell('r2a'))
      table = build_table(header: [row(cell('H'))], body: body)
      tf = described_class.new(table, style: style, min_row_height: 25.0)
      # Room for the caption-less header + rows 1-3 but not more; rows
      # 1-2 are welded so the head must take both or neither.
      head, tail = tf.do_split(200.0, 105.0, nil)
      expect(head).not_to be_nil
      expect(head.table.body.length).to eq(3)
      expect(tail.table.body.length).to eq(5)
    end

    it 'returns no head when the first welded group does not fit' do
      body = [row(cell('r1a'), cell('r1b', rowspan: 4))] +
             (2..4).map { |i| row(cell("r#{i}")) }
      table = build_table(header: [row(cell('H'))], body: body)
      tf = described_class.new(table, style: style, min_row_height: 25.0)
      head, tail = tf.do_split(200.0, 60.0, nil)
      expect(head).to be_nil
      expect(tail.table.body.length).to eq(4)
      expect(tail.continued).to be(false)
    end

    it 'carries footnotes with the part holding the last row' do
      fn = Arrolio::Content::Footnote.new(
        marker: 'a',
        body: [Arrolio::Content::Paragraph.new(
          [Arrolio::Content::InlineRun.new('body', style_id: :inline)]
        )]
      )
      body = (1..8).map { |i| row(cell("r#{i}")) }
      table = build_table(header: [row(cell('H'))], body: body, footnotes: [fn])
      tf = described_class.new(table, style: style, min_row_height: 25.0)
      head, tail = tf.do_split(200.0, 105.0, nil)
      expect(head.table.footnotes).to be_empty
      expect(tail.table.footnotes).to eq([fn])
    end
  end
end
