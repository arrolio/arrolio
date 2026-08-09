# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::GenericAdapter do
  let(:rules) do
    {
      'metadata' => { 'root' => 'bibdata', 'fields' => {} },
      'element_mapping' => {
        'clause' => { 'content_type' => 'section' },
        'p' => { 'content_type' => 'paragraph' }
      },
      'sections' => { 'container' => 'sections' }
    }
  end

  let(:adapter) { described_class.new(rules: rules) }

  describe 'normalize_text' do
    it 'converts Unicode thin spaces to ASCII spaces' do
      xml = '<root><bibdata/><sections><clause><p>5 +5</p></clause></sections></root>'
      doc = adapter.convert(xml)
      para = doc.sections.first.children.first
      expect(para.text).to include('5 +5')
      expect(para.text).not_to include(' ')
    end

    it 'converts no-break spaces to ASCII spaces' do
      xml = '<root><bibdata/><sections><clause><p>value</p></clause></sections></root>'
      doc = adapter.convert(xml)
      para = doc.sections.first.children.first
      expect(para.text).to include('value')
      expect(para.text).not_to include(' ')
    end

    it 'preserves newlines as spaces in multi-element text' do
      xml = '<root><bibdata/><sections><clause><p>before after</p></clause></sections></root>'
      doc = adapter.convert(xml)
      para = doc.sections.first.children.first
      expect(para.text).to include('before')
      expect(para.text).to include('after')
    end
  end
end
