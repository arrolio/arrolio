# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Engine::CrossReferenceRegistry do
  let(:registry) { described_class.new }

  describe '#record' do
    it 'stores an entry' do
      registry.record(id: 'sec-1', number: '1', title: 'Intro', level: 1, page_number: 5)
      expect(registry.count).to eq(1)
    end

    it 'records entries without an id' do
      registry.record(id: nil, number: '2', title: 'Scope', level: 1, page_number: 6)
      expect(registry.count).to eq(1)
    end
  end

  describe '#page_number_for' do
    it 'resolves an id to a page number' do
      registry.record(id: 'sec-3', number: '3', title: 'Terms', level: 1, page_number: 9)
      expect(registry.page_number_for('sec-3')).to eq(9)
    end

    it 'returns nil for unknown ids' do
      expect(registry.page_number_for('nonexistent')).to be_nil
    end
  end

  describe '#entry_for' do
    it 'returns the full entry' do
      registry.record(id: 'fig-1', number: '1', title: 'Figure 1', level: 2, page_number: 12)
      entry = registry.entry_for('fig-1')
      expect(entry.title).to eq('Figure 1')
      expect(entry.page_number).to eq(12)
    end
  end

  describe '#toc_entries' do
    before do
      registry.record(id: '1', number: '1', title: 'Intro', level: 1, page_number: 5)
      registry.record(id: '2', number: '2', title: 'Scope', level: 1, page_number: 6)
      registry.record(id: '2.1', number: '2.1', title: 'Sub', level: 2, page_number: 6)
      registry.record(id: '3', number: '3', title: 'Terms', level: 1, page_number: 9)
    end

    it 'returns all entries in document order' do
      entries = registry.toc_entries
      expect(entries.length).to eq(4)
      expect(entries.first.title).to eq('Intro')
    end

    it 'filters by max_level' do
      entries = registry.toc_entries(max_level: 1)
      expect(entries.length).to eq(3)
      expect(entries.none? { |e| e.level > 1 }).to be(true)
    end
  end

  describe '#empty?' do
    it 'is true when no entries recorded' do
      expect(registry).to be_empty
    end

    it 'is false when entries exist' do
      registry.record(id: 'x', number: '1', title: 'T', level: 1, page_number: 1)
      expect(registry).not_to be_empty
    end
  end
end
