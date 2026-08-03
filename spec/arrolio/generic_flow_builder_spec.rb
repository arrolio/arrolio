# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'fileutils'

RSpec.describe Arrolio::GenericFlowBuilder do
  let(:layout_spec_path) { File.expand_path('../fixtures/flavors/sample/layout_spec.yml', __dir__) }
  let(:flow_rules_path) { File.expand_path('../fixtures/flavors/sample/flow_rules.yml', __dir__) }
  let(:layout_spec) { Arrolio::LayoutSpec::Loader.load(layout_spec_path) }
  let(:builder) { described_class.new(layout_spec: layout_spec, rules: flow_rules_path) }

  def document_with(metadata: {}, cover: {}, sections: [], preface: [], bibliography: [])
    Arrolio::Content::Document.new(
      metadata: metadata, cover: cover,
      sections: sections, preface: preface, bibliography: bibliography
    )
  end

  def section(title: 'Scope', number: '1', level: 1, children: [])
    Arrolio::Content::Section.new(
      title: title, number: number, level: level,
      style_id: :"section_body_#{level}", title_style_id: :heading_1,
      children: children
    )
  end

  it 'reads flow rules from a path or hash' do
    from_path = described_class.new(layout_spec: layout_spec, rules: flow_rules_path)
    from_hash = described_class.new(layout_spec: layout_spec, rules: YAML.safe_load_file(flow_rules_path))
    expect(from_path.rules).to eq(from_hash.rules)
  end

  it 'builds a cover sequence with text + spacers' do
    flowables = builder.build(
      document_with(
        metadata: { docidentifier: 'OIML R 60-1' },
        cover: { docidentifier: 'OIML R 60-1' }
      )
    )
    roles = flowables.grep(Arrolio::Flowables::PageSequenceStart).map(&:role)
    expect(roles).to include(:cover)
  end

  it 'renders a body section with heading + paragraphs' do
    paragraph = Arrolio::Content::Paragraph.new(
      [Arrolio::Content::InlineRun.new('Hello world')],
      style_id: :body
    )
    document = document_with(
      metadata: { docidentifier: 'OIML R 60-1' },
      cover: { docidentifier: 'OIML R 60-1' },
      sections: [section(children: [paragraph])]
    )
    flowables = builder.build(document)
    headings = flowables.grep(Arrolio::Flowables::HeadingFlowable)
    paragraphs = flowables.grep(Arrolio::Flowables::TextFlowable)
    expect(headings.length).to eq(1)
    expect(headings.first.title).to eq('Scope')
    expect(paragraphs.length).to be >= 2 # cover label, body paragraph
  end

  it 'inlines the section number when the section has no title' do
    inline_section = Arrolio::Content::Section.new(
      number: '1.1', level: 2, title: nil,
      children: [Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('continued')],
        style_id: :body
      )],
      style_id: :section_body_2, title_style_id: :heading_2
    )
    flowables = builder.build(document_with(
      sections: [inline_section],
      cover: {},
      metadata: { docidentifier: 'X' }
    ))
    paragraphs = flowables.grep(Arrolio::Flowables::TextFlowable)
    expect(paragraphs.flat_map { |flowable| flowable.runs.map(&:text) }.join).to include('1.1')
  end
end
