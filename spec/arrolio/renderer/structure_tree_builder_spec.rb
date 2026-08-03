# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Renderer::StructureTreeBuilder do
  let(:document) { Pdfrb::Document.new }
  let(:builder) { described_class.new(document) }

  describe '#record' do
    it 'records a structure entry' do
      builder.record(type: :heading, page_number: 1, text: 'Introduction')
      expect(builder.count).to eq(1)
    end

    it 'assigns sequential MCIDs' do
      builder.record(type: :heading, page_number: 1)
      builder.record(type: :paragraph, page_number: 1)
      builder.record(type: :figure, page_number: 2)
      expect(builder.entries.map(&:mcid)).to eq([0, 1, 2])
    end

    it 'maps type to PDF structure type' do
      builder.record(type: :heading1, page_number: 1)
      expect(builder.entries.first.type).to eq(:H1)
    end

    it 'defaults unknown types to :P' do
      builder.record(type: :unknown, page_number: 1)
      expect(builder.entries.first.type).to eq(:P)
    end
  end

  describe '#build' do
    it 'returns nil when no entries' do
      expect(builder.build).to be_nil
    end

    it 'attaches StructTreeRoot to catalog' do
      builder.record(type: :paragraph, page_number: 1)
      builder.build
      expect(document.catalog.value[:StructTreeRoot]).not_to be_nil
    end
  end

  describe '#empty?' do
    it 'is true initially' do
      expect(builder).to be_empty
    end

    it 'is false after recording' do
      builder.record(type: :paragraph, page_number: 1)
      expect(builder).not_to be_empty
    end
  end
end
