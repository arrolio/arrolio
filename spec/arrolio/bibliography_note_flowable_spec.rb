# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::GenericFlowBuilder do
  let(:layout_spec_path) { File.expand_path('../fixtures/flavors/sample/layout_spec.yml', __dir__) }
  let(:flow_rules_path) { File.expand_path('../fixtures/flavors/sample/flow_rules.yml', __dir__) }
  let(:layout_spec) { Arrolio::LayoutSpec::Loader.load(layout_spec_path) }
  let(:builder) { described_class.new(layout_spec: layout_spec, rules: flow_rules_path) }

  describe 'bibliography rendering' do
    it 'emits NoteFlowable with tag as marker' do
      ref = Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('Some Reference Text')], style_id: :bibitem
      )
      item = Arrolio::Content::BibliographyItem.new(tag: '[1]', formattedref: ref)
      bib_section = Arrolio::Content::Section.new(
        title: 'Bibliography', level: 1, children: [item],
        style_id: :section_body_1, title_style_id: :heading_1
      )
      document = Arrolio::Content::Document.new(
        metadata: { docidentifier: 'X' }, cover: { docidentifier: 'X' },
        sections: [bib_section], preface: [], bibliography: []
      )

      flowables = builder.build(document)
      notes = flowables.grep(Arrolio::Flowables::NoteFlowable)
      expect(notes).not_to be_empty
    end

    it 'falls back to paragraph when tag is empty' do
      ref = Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('No Tag Reference')], style_id: :bibitem
      )
      item = Arrolio::Content::BibliographyItem.new(tag: '', formattedref: ref)
      bib_section = Arrolio::Content::Section.new(
        title: 'Bibliography', level: 1, children: [item],
        style_id: :section_body_1, title_style_id: :heading_1
      )
      document = Arrolio::Content::Document.new(
        metadata: { docidentifier: 'X' }, cover: { docidentifier: 'X' },
        sections: [bib_section], preface: [], bibliography: []
      )

      flowables = builder.build(document)
      texts = flowables.grep(Arrolio::Flowables::TextFlowable)
      expect(texts.map { |t| t.runs.map(&:text).join }).to include(include('No Tag Reference'))
    end
  end
end
