# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Content::Example dispatch through GenericFlowBuilder' do
  let(:flavor_dir) { File.expand_path('../fixtures/flavors/sample', __dir__) }
  let(:layout_spec) { Arrolio::LayoutSpec::Loader.load(File.join(flavor_dir, 'layout_spec.yml')) }
  let(:rules_path) { File.join(flavor_dir, 'flow_rules.yml') }
  let(:builder) { Arrolio::GenericFlowBuilder.new(layout_spec: layout_spec, rules: rules_path) }

  it 'emits a NoteFlowable for Content::Example' do
    body = [Arrolio::Content::Paragraph.new(
      [Arrolio::Content::InlineRun.new('Example body text.')],
      style_id: :example
    )]
    example = Arrolio::Content::Example.new(label: 'EXAMPLE 1', body: body)
    section = Arrolio::Content::Section.new(
      title: 'S', level: 1, children: [example],
      style_id: :section_body_1, title_style_id: :heading_1
    )
    document = Arrolio::Content::Document.new(
      metadata: { docidentifier: 'X' }, sections: [section]
    )

    flowables = builder.build(document)
    note_flowables = flowables.grep(Arrolio::Flowables::NoteFlowable)
    expect(note_flowables.length).to eq(1)

    note = note_flowables.first
    expect(note.label_mode).to eq(:block)

    boxes, = note.emit(100.0, 500.0, 400.0, nil)
    text_boxes = boxes.select { |b| b.kind == :text }.sort_by { |b| -b.y }
    line_text = lambda do |box|
      box.data[:lines].map { |l| l.placed_runs.map { |pr| pr.run.text }.join }.join
    end
    expect(line_text.call(text_boxes.first)).to eq('EXAMPLE 1:')
    body_box = text_boxes.last
    expect(body_box.x).to be > 100.0
    expect(line_text.call(body_box)).to include('Example body text.')
  end

  it 'GenericAdapter#convert_example emits Content::Example from <example>' do
    rules = { 'sections' => { 'container' => 'sections' },
              'element_mapping' => { 'clause' => { 'content_type' => 'section' },
                                     'example' => { 'content_type' => 'example' } },
              'selectors' => { 'heading' => 'fmt-title', 'paragraph' => 'p',
                               'note_label' => 'fmt-name', 'id_attribute' => 'id' } }
    adapter = Arrolio::GenericAdapter.new(rules: rules)
    xml = '<doc><sections><clause>' \
          '<example id="ex1"><fmt-name>EXAMPLE 1</fmt-name>' \
          '<p>Text.</p></example></clause></sections></doc>'
    example = adapter.convert(xml).sections.first.children.first
    expect(example).to be_a(Arrolio::Content::Example)
    expect(example.label).to eq('EXAMPLE 1')
    expect(example.body.first.text).to eq('Text.')
  end
end
