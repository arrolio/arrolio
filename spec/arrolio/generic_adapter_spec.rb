# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe Arrolio::GenericAdapter do
  let(:rules) do
    {
      'metadata' => { 'root' => 'bibdata', 'fields' => { 'docidentifier' => 'docidentifier' } },
      'element_mapping' => {
        'clause' => { 'content_type' => 'section' },
        'p' => { 'content_type' => 'paragraph' },
        'table' => { 'content_type' => 'table' },
        'figure' => { 'content_type' => 'figure' },
        'ul' => { 'content_type' => 'list', 'kind' => 'bullet' },
        'note' => { 'content_type' => 'note' }
      },
      'inline_styles' => {
        'strong' => 'strong', 'em' => 'em'
      },
      'block_level_elements' => ['note', 'table', 'figure', 'clause'],
      'skip_metadata_elements' => ['asciimath', 'image'],
      'skip_elements' => ['title', 'fmt-title', 'fmt-xref-label'],
      'tab_replacements' => { 'biblio-tag' => ' ' }
    }
  end

  let(:adapter) { described_class.new(rules: rules) }

  def parse(xml)
    REXML::Document.new(xml).root
  end

  describe '#convert' do
    it 'parses a minimal document' do
      xml = <<~XML
        <metanorma>
          <bibdata><docidentifier>OIML R 60-1</docidentifier></bibdata>
          <sections>
            <clause id="c1">
              <fmt-title depth="1"><semx element="autonum">1</semx><tab/><semx element="title">Intro</semx></fmt-title>
              <p>Hello world</p>
            </clause>
          </sections>
        </metanorma>
      XML
      doc = adapter.convert(xml)
      expect(doc.metadata[:docidentifier]).to eq('OIML R 60-1')
      expect(doc.sections.length).to eq(1)
    end

    it 'collects inline runs from paragraphs' do
      xml = '<p>Hello <strong>bold</strong> text</p>'
      parse(xml)
      # Access the private method through the adapter's logic
      doc = adapter.convert('<metanorma><sections><clause><p>Test</p></clause></sections></metanorma>')
      expect(doc.sections.first.children.first).to be_a(Arrolio::Content::Paragraph)
    end

    it 'skips block-level elements during inline collection' do
      xml = '<p>before<note><p>hidden</p></note>after</p>'
      adapter2 = described_class.new(rules: rules.merge(
        'element_mapping' => rules['element_mapping'].merge('p' => { 'content_type' => 'paragraph' })
      ))
      doc = adapter2.convert("<metanorma><sections><clause>#{xml}</clause></sections></metanorma>")
      # The note should not be inlined into the paragraph text
      section = doc.sections.first
      para = section.children.find { |c| c.is_a?(Arrolio::Content::Paragraph) }
      expect(para.text).to include('before')
      expect(para.text).to include('after')
      expect(para.text).not_to include('hidden')
    end
  end

  describe 'with a flavor adapter_rules.yml' do
    let(:rules_path) { File.expand_path('../fixtures/flavors/sample/adapter_rules.yml', __dir__) }
    let(:adapter) { described_class.new(rules: rules_path) }

    it 'loads the YAML configuration' do
      skip 'sample adapter_rules.yml not found' unless File.exist?(rules_path)
      expect(adapter.rules).to be_a(Hash)
      expect(adapter.rules['element_mapping']).to be_a(Hash)
    end
  end

  describe 'heading number delimiter extraction' do
    let(:rules) do
      {
        'selectors' => { 'heading' => 'fmt-title' },
        'metadata' => { 'root' => 'bibdata', 'fields' => {} },
        'element_mapping' => { 'clause' => { 'content_type' => 'section' } },
        'sections' => { 'container' => 'sections' }
      }
    end

    it 'includes the autonum delimiter between number parts' do
      xml = <<~XML
        <root>
          <sections>
            <clause>
              <fmt-title depth="2">
                <span class="fmt-caption-label">
                  <semx element="autonum">2</semx>
                  <span class="fmt-autonum-delim">.</span>
                  <semx element="autonum">1</semx>
                </span>
                <semx element="title">Scope</semx>
              </fmt-title>
              <p>body</p>
            </clause>
          </sections>
          <bibdata/>
        </root>
      XML

      doc = adapter.convert(xml)
      section = doc.sections.first
      expect(section.number).to eq('2.1')
      expect(section.title).to eq('Scope')
    end

    it 'returns nil title when the heading has only autonum content' do
      xml = <<~XML
        <root>
          <sections>
            <clause>
              <fmt-title depth="2">
                <span class="fmt-caption-label">
                  <semx element="autonum">2</semx>
                  <span class="fmt-autonum-delim">.</span>
                  <semx element="autonum">1</semx>
                </span>
              </fmt-title>
              <p>body</p>
            </clause>
          </sections>
          <bibdata/>
        </root>
      XML

      doc = adapter.convert(xml)
      section = doc.sections.first
      expect(section.number).to eq('2.1')
      expect(section.title).to be_nil
      expect(section.heading?).to be(false)
    end
  end

  describe 'derived metadata fields' do
    let(:rules) do
      {
        'metadata' => {
          'root' => 'bibdata',
          'fields' => {
            'revision_date' => 'version',
            'language' => 'language'
          }
        }
      }
    end

    it 'computes revision_year and edition_label from revision_date + language' do
      xml = <<~XML
        <root>
          <bibdata>
            <version>2021-10-01</version>
            <language current="true">en</language>
          </bibdata>
        </root>
      XML

      doc = adapter.convert(xml)
      expect(doc.metadata[:revision_year]).to eq('2021')
      expect(doc.metadata[:edition_label]).to eq('2021 (E)')
    end

    it 'skips derived fields when revision_date is missing' do
      xml = '<root><bibdata><language current="true">en</language></bibdata></root>'
      doc = adapter.convert(xml)
      expect(doc.metadata.key?(:edition_label)).to be(false)
    end

    it 'skips derived fields when revision_date is not a year prefix' do
      xml = '<root><bibdata><version>n/a</version><language current="true">en</language></bibdata></root>'
      doc = adapter.convert(xml)
      expect(doc.metadata.key?(:edition_label)).to be(false)
    end
  end
end
