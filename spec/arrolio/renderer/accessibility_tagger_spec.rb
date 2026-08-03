# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Renderer::AccessibilityTagger do
  let(:document) { Pdfrb::Document.new }
  let(:tagger) { described_class.new(document) }

  describe '#alt_property' do
    it 'returns a dictionary with /Alt entry' do
      prop = tagger.alt_property('OIML logo')
      expect(prop).not_to be_nil
    end

    it 'returns nil for nil input' do
      expect(tagger.alt_property(nil)).to be_nil
    end

    it 'returns nil for empty string' do
      expect(tagger.alt_property('')).to be_nil
    end
  end

  describe '#actual_text_property' do
    it 'returns a dictionary with /ActualText entry' do
      prop = tagger.actual_text_property('E = mc^2')
      expect(prop).not_to be_nil
    end

    it 'returns nil for nil input' do
      expect(tagger.actual_text_property(nil)).to be_nil
    end
  end

  describe '#combined_property' do
    it 'combines alt + actual text when both present' do
      prop = tagger.combined_property(alt_text: 'Formula', actual_text: 'E=mc^2')
      expect(prop).not_to be_nil
    end

    it 'returns nil when neither is provided' do
      expect(tagger.combined_property).to be_nil
    end

    it 'works with only alt text' do
      prop = tagger.combined_property(alt_text: 'Image')
      expect(prop).not_to be_nil
    end
  end

  describe '#next_tag' do
    it 'returns sequential marked content tags' do
      expect(tagger.next_tag).to eq(:MC1)
      expect(tagger.next_tag).to eq(:MC2)
      expect(tagger.next_tag).to eq(:MC3)
    end
  end
end
