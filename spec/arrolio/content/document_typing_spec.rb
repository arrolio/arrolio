# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Content::Document do
  describe 'strict Section typing in constructor' do
    let(:valid_section) { Arrolio::Content::Section.new(title: 'A', level: 1) }
    let(:invalid_item) { Arrolio::Content::Paragraph.new([Arrolio::Content::InlineRun.new('x')]) }

    it 'accepts a document with only Section instances in sections' do
      doc = described_class.new(sections: [valid_section])
      expect(doc.sections).to eq([valid_section])
    end

    it 'raises ContentError when a Paragraph is in sections' do
      expect do
        described_class.new(sections: [invalid_item])
      end.to raise_error(Arrolio::ContentError, /sections must contain only Content::Section/)
    end

    it 'raises ContentError when a Paragraph is in preface' do
      expect do
        described_class.new(preface: [invalid_item])
      end.to raise_error(Arrolio::ContentError, /preface must contain only Content::Section/)
    end

    it 'raises ContentError when a Paragraph is in bibliography' do
      expect do
        described_class.new(bibliography: [invalid_item])
      end.to raise_error(Arrolio::ContentError, /bibliography must contain only Content::Section/)
    end

    it 'attaches the offending node to the error' do
      error = begin
                described_class.new(sections: [invalid_item])
              rescue Arrolio::ContentError => e
                e
              end
      expect(error.node).to be(invalid_item)
    end
  end
end
