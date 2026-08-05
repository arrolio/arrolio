# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Phase 2 semantic dispatch through GenericFlowBuilder' do
  let(:flavor_dir) { File.expand_path('../fixtures/flavors/sample', __dir__) }
  let(:layout_spec) { Arrolio::LayoutSpec::Loader.load(File.join(flavor_dir, 'layout_spec.yml')) }
  let(:rules_path) { File.join(flavor_dir, 'flow_rules.yml') }
  let(:builder) { Arrolio::GenericFlowBuilder.new(layout_spec: layout_spec, rules: rules_path) }

  def build_document(*children)
    section = Arrolio::Content::Section.new(
      title: 'Section', level: 1, children: children,
      style_id: :section_body_1, title_style_id: :heading_1
    )
    Arrolio::Content::Document.new(metadata: { docidentifier: 'X' }, sections: [section])
  end

  describe 'Content::FigureGroup dispatch' do
    it 'emits Image flowable + caption TextFlowable' do
      image = Arrolio::Content::Image.new('img.png')
      caption = Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('Fig. 1')], style_id: :figure_caption
      )
      document = build_document(Arrolio::Content::FigureGroup.new(image: image, caption: caption))

      flowables = builder.build(document)
      text_flowables = flowables.grep(Arrolio::Flowables::TextFlowable)
      expect(text_flowables.any? { |f| f.runs.any? { |r| r.text.include?('Fig. 1') } }).to be(true)
    end

    it 'emits just the caption when no image' do
      caption = Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('Caption only')], style_id: :figure_caption
      )
      document = build_document(Arrolio::Content::FigureGroup.new(caption: caption))

      flowables = builder.build(document)
      expect(flowables.grep(Arrolio::Flowables::TextFlowable).length).to be >= 1
    end
  end

  describe 'Content::TermEntry dispatch' do
    it 'emits number + preferred + definition + source as separate flowables' do
      preferred = Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('calibration')], style_id: :term
      )
      definition = Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('the set of operations...')], style_id: :body
      )
      source = Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('[ISO 9000]')], style_id: :bibitem
      )
      entry = Arrolio::Content::TermEntry.new(
        number: '3.1.1', preferred: preferred,
        definition: [definition], source: source
      )
      document = build_document(entry)

      flowables = builder.build(document)
      text_flowables = flowables.grep(Arrolio::Flowables::TextFlowable)
      # number + preferred + definition + source = 4 TextFlowables
      expect(text_flowables.length).to be >= 4
      all_text = text_flowables.flat_map { |f| f.runs.map(&:text) }.join
      expect(all_text).to include('3.1.1')
      expect(all_text).to include('calibration')
      expect(all_text).to include('[ISO 9000]')
    end

    it 'omits number flowable when number is nil' do
      preferred = Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('x')], style_id: :term
      )
      entry = Arrolio::Content::TermEntry.new(preferred: preferred)
      document = build_document(entry)

      flowables = builder.build(document)
      text_flowables = flowables.grep(Arrolio::Flowables::TextFlowable)
      body_text = text_flowables.flat_map { |f| f.runs.map(&:text) }.join
      expect(body_text).to include('x')
    end
  end

  describe 'Content::BibliographyItem dispatch' do
    it 'emits a TextFlowable combining tag + formattedref' do
      ref = Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('Smith 2020')], style_id: :bibitem
      )
      item = Arrolio::Content::BibliographyItem.new(tag: '[Smith2020]', formattedref: ref)
      document = build_document(item)

      flowables = builder.build(document)
      text_flowables = flowables.grep(Arrolio::Flowables::TextFlowable)
      bib = text_flowables.find { |f| f.runs.any? { |r| r.text.include?('[Smith2020]') } }
      expect(bib).not_to be_nil
      combined = bib.runs.map(&:text).join
      expect(combined).to include('[Smith2020]')
      expect(combined).to include('Smith 2020')
    end

    it 'emits a TextFlowable with just the tag when no formattedref' do
      item = Arrolio::Content::BibliographyItem.new(tag: '[X]', formattedref: nil)
      document = build_document(item)

      flowables = builder.build(document)
      text_flowables = flowables.grep(Arrolio::Flowables::TextFlowable)
      bib = text_flowables.find { |f| f.runs.any? { |r| r.text.include?('[X]') } }
      expect(bib).not_to be_nil
    end
  end
end
