# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Harness::TextExtractor do
  let(:pdf_path) { File.expand_path('../out.pdf', __dir__) }
  let(:extractor) { described_class.new(pdf_path) }

  describe '#pages' do
    it 'returns an array of page strings', :e2e do
      skip 'out.pdf not found' unless File.exist?(pdf_path)

      pages = extractor.pages
      expect(pages).to be_an(Array)
      expect(pages.length).to be > 0
    end

    it 'returns empty array for non-existent file' do
      ext = described_class.new('/nonexistent/path.pdf')
      expect(ext.pages).to eq([])
    end
  end

  describe '#word_count' do
    it 'returns a non-negative integer', :e2e do
      skip 'out.pdf not found' unless File.exist?(pdf_path)

      expect(extractor.word_count).to be >= 0
    end
  end
end
