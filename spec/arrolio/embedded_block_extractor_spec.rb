# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

RSpec.describe Arrolio::EmbeddedBlockExtractor do
  let(:rules) do
    {
      'element_mapping' => {
        'note' => { 'content_type' => 'note' },
        'example' => { 'content_type' => 'example' },
        'p' => { 'content_type' => 'paragraph' }
      },
      'block_level_elements' => ['note', 'example', 'table']
    }
  end

  let(:registry) { { 'note' => :convert_note, 'example' => :convert_example } }
  let(:extractor) { described_class.new(rules, registry) }

  def parse(xml)
    REXML::Document.new(xml).root
  end

  it 'returns empty array when no block elements are nested' do
    elem = parse('<p>just text</p>')
    results = extractor.extract(elem) { |_| [] }
    expect(results).to eq([])
  end

  it 'finds note nested inside paragraph' do
    elem = parse('<p>text before<note><p>note body</p></note>text after</p>')
    calls = []
    extractor.extract(elem) do |converter, descendant, _mapping|
      calls << [converter, descendant.name]
      []
    end
    expect(calls).to include([:convert_note, 'note'])
  end

  it 'does not find notes inside section elements' do
    elem = parse('<p>text<clause><note><p>inner</p></note></clause></p>')
    calls = []
    extractor.extract(elem) do |_converter, descendant, _mapping|
      calls << descendant.name
      []
    end
    expect(calls).not_to include('note')
  end

  it 'handles nil block_level_elements in rules' do
    extractor = described_class.new({}, registry)
    elem = parse('<p>text</p>')
    results = extractor.extract(elem) { |_| [] }
    expect(results).to eq([])
  end
end
