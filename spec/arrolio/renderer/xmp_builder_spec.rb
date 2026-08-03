# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Renderer::XmpBuilder do
  let(:metadata) { { title: 'Test Doc', author: 'Jane Doe' } }

  describe '#build' do
    it 'wraps content in xpacket processing instructions' do
      result = described_class.new(metadata).build
      expect(result).to include('<?xpacket begin')
      expect(result).to include('<?xpacket end')
    end

    it 'includes dc:title when title is present' do
      result = described_class.new(metadata).build
      expect(result).to include('<dc:title>')
      expect(result).to include('Test Doc')
    end

    it 'includes dc:creator when author is present' do
      result = described_class.new(metadata).build
      expect(result).to include('<dc:creator>')
      expect(result).to include('Jane Doe')
    end

    it 'includes pdf:Producer' do
      result = described_class.new(metadata).build
      expect(result).to include('<pdf:Producer>')
    end

    it 'includes xmp:CreatorTool' do
      result = described_class.new(metadata).build
      expect(result).to include('<xmp:CreatorTool>')
    end

    it 'omits dc:title when title is absent' do
      result = described_class.new(author: 'X').build
      expect(result).not_to include('<dc:title>')
    end

    it 'escapes XML special characters in values' do
      result = described_class.new(title: 'A & B < C > D').build
      expect(result).to include('A &amp; B &lt; C &gt; D')
      expect(result).not_to include('A & B < C > D')
    end

    it 'produces valid-looking XML' do
      result = described_class.new(metadata).build
      expect(result).to include('xmlns:rdf=')
      expect(result).to include('xmlns:dc=')
      expect(result).to include('xmlns:pdf=')
      expect(result).to include('xmlns:xmp=')
    end
  end

  describe 'with empty metadata' do
    it 'still produces a valid packet' do
      result = described_class.new.build
      expect(result).to include('<?xpacket begin')
      expect(result).to include('<?xpacket end')
      expect(result).to include('<pdf:Producer>')
    end
  end
end
