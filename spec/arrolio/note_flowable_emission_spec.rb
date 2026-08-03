# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'NoteFlowable emission from Content::Note' do
  let(:flavor_dir) { File.expand_path('../fixtures/flavors/sample', __dir__) }
  let(:layout_spec) { Arrolio::LayoutSpec::Loader.load(File.join(flavor_dir, 'layout_spec.yml')) }
  let(:rules_path) { File.join(flavor_dir, 'flow_rules.yml') }
  let(:builder) { Arrolio::GenericFlowBuilder.new(layout_spec: layout_spec, rules: rules_path) }

  it 'emits a NoteFlowable when a Section contains a Content::Note' do
    note = Arrolio::Content::Note.new(
      label: 'NOTE',
      body: [Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('Body of the note.')],
        style_id: :note
      )]
    )
    section = Arrolio::Content::Section.new(
      title: 'Section', level: 1,
      children: [note],
      style_id: :section_body_1, title_style_id: :heading_1
    )
    document = Arrolio::Content::Document.new(
      metadata: { docidentifier: 'X' },
      sections: [section]
    )

    flowables = builder.build(document)
    note_flowables = flowables.grep(Arrolio::Flowables::NoteFlowable)
    expect(note_flowables.length).to eq(1)
    expect(note_flowables.first.items.length).to eq(1)
  end

  it 'preserves multi-paragraph note body as a single grouped NoteFlowable' do
    note = Arrolio::Content::Note.new(
      label: 'WARNING',
      body: [
        Arrolio::Content::Paragraph.new([Arrolio::Content::InlineRun.new('first')], style_id: :note),
        Arrolio::Content::Paragraph.new([Arrolio::Content::InlineRun.new('second')], style_id: :note)
      ]
    )
    section = Arrolio::Content::Section.new(
      title: 'S', level: 1, children: [note],
      style_id: :section_body_1, title_style_id: :heading_1
    )
    document = Arrolio::Content::Document.new(metadata: { docidentifier: 'X' }, sections: [section])

    flowables = builder.build(document)
    note_flowables = flowables.grep(Arrolio::Flowables::NoteFlowable)
    expect(note_flowables.length).to eq(1)
    _, body_flowables = note_flowables.first.items.first
    expect(body_flowables.length).to eq(2)
  end

  it 'ListFlowable accepts a String marker or a Flowable marker' do
    style = Arrolio::Style::Definition.new
    items_string = [['1)', [Arrolio::Flowables::TextFlowable.new(
      [Arrolio::InlineRun.new('item', style: style)], style: style
    )]]]
    list = Arrolio::Flowables::ListFlowable.new(items_string, kind: :ordered, style: style)
    boxes, consumed = list.emit(0, 100, 200, nil)
    expect(boxes).to be_an(Array)
    expect(consumed).to be >= 0

    marker_flow = Arrolio::Flowables::TextFlowable.new(
      [Arrolio::InlineRun.new('NOTE', style: style)],
      style: style
    )
    items_flowable = [[marker_flow, []]]
    list2 = Arrolio::Flowables::ListFlowable.new(items_flowable, kind: :bullet, style: style)
    boxes2, = list2.emit(0, 100, 200, nil)
    expect(boxes2).to be_an(Array)
  end
end
