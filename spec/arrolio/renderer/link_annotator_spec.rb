# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Renderer::LinkAnnotator do
  let(:document) { Pdfrb::Document.new }
  let(:annotator) { described_class.new(document) }

  describe '#record_link' do
    it 'stores the link for later flush' do
      annotator.record_link(x: 100, y: 200, width: 50, height: 12, uri: 'https://example.com')
      expect(annotator.pending_links.length).to eq(1)
    end

    it 'stores multiple links' do
      3.times do |i|
        annotator.record_link(x: i * 100, y: 200, width: 50, height: 12, uri: "https://ex#{i}.com")
      end
      expect(annotator.pending_links.length).to eq(3)
    end
  end

  describe '#flush' do
    let(:page) { document.pages.add }

    it 'does nothing when no links are pending' do
      annotator.flush(page)
      expect(page.value[:Annots]).to be_nil
    end

    it 'emits /Annots array when links are pending' do
      annotator.record_link(x: 10, y: 20, width: 30, height: 12, uri: 'https://x.com')
      annotator.flush(page)
      expect(page.value[:Annots]).to be_an(Array)
      expect(page.value[:Annots].length).to eq(1)
    end

    it 'clears pending links after flush' do
      annotator.record_link(x: 10, y: 20, width: 30, height: 12, uri: 'https://x.com')
      annotator.flush(page)
      expect(annotator.pending_links).to be_empty
    end
  end
end
