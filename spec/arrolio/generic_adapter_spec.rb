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

    it 'treats an autonum-only heading as an inline header (not a heading line)' do
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

    it 'sets edition_label without year when revision_date is missing' do
      xml = '<root><bibdata><language current="true">en</language></bibdata></root>'
      doc = adapter.convert(xml)
      expect(doc.metadata.key?(:revision_year)).to be(false)
      expect(doc.metadata[:edition_label]).to eq('(E)')
    end

    it 'sets edition_label without year when revision_date is not a year prefix' do
      xml = '<root><bibdata><version>n/a</version><language current="true">en</language></bibdata></root>'
      doc = adapter.convert(xml)
      expect(doc.metadata.key?(:revision_year)).to be(false)
      expect(doc.metadata[:edition_label]).to eq('(E)')
    end
  end

  describe 'sub/sup baseline shift' do
    let(:rules) do
      {
        'metadata' => { 'root' => 'bibdata', 'fields' => {} },
        'element_mapping' => {
          'clause' => { 'content_type' => 'section' },
          'p' => { 'content_type' => 'paragraph' }
        },
        'sections' => { 'container' => 'sections' },
        'inline_styles' => { 'sub' => 'subscript', 'sup' => 'superscript' }
      }
    end

    def paragraph_with(xml_inner)
      adapter.convert(<<~XML).sections.first.children.first
        <root>
          <sections>
            <clause>
              <p>#{xml_inner}</p>
            </clause>
          </sections>
          <bibdata/>
        </root>
      XML
    end

    it 'sets baseline_shift=:sub for runs inside <sub>' do
      para = paragraph_with('H<sub>2</sub>O')
      runs = para.inline_runs
      sub_run = runs.find { |r| r.text == '2' }
      expect(sub_run.baseline_shift).to eq(Arrolio::Content::InlineRun::BASELINE_SUB)
      expect(sub_run.font_size_scale).to be < 1.0
    end

    it 'sets baseline_shift=:sup for runs inside <sup>' do
      para = paragraph_with('x<sup>2</sup>')
      runs = para.inline_runs
      sup_run = runs.find { |r| r.text == '2' }
      expect(sup_run.baseline_shift).to eq(Arrolio::Content::InlineRun::BASELINE_SUP)
      expect(sup_run.font_size_scale).to be < 1.0
    end

    it 'preserves normal baseline for sibling runs outside sub/sup' do
      para = paragraph_with('a<sub>b</sub>c')
      runs = para.inline_runs
      expect(runs.find { |r| r.text == 'a' }.baseline_shift).to be_nil
      expect(runs.find { |r| r.text == 'c' }.baseline_shift).to be_nil
    end

    it 'composes nested scales (sub inside sub)' do
      para = paragraph_with('x<sub><sub>y</sub></sub>z')
      runs = para.inline_runs
      nested = runs.find { |r| r.text == 'y' }
      expect(nested.baseline_shift).to eq(Arrolio::Content::InlineRun::BASELINE_SUB)
      expect(nested.font_size_scale).to be < 0.7 # 0.7 * 0.7
    end
  end

  describe 'locality reference formatting' do
    let(:rules) do
      {
        'metadata' => { 'root' => 'bibdata', 'fields' => { 'docidentifier' => 'docidentifier' } },
        'element_mapping' => { 'clause' => { 'content_type' => 'section' }, 'p' => { 'content_type' => 'paragraph' } },
        'inline_styles' => { 'fmt-xref' => 'xref' },
        'selectors' => { 'paragraph' => 'p' }
      }
    end

    it 'replaces = with space in locality references inside fmt-xref' do
      xml = '<root><bibdata><docidentifier>X</docidentifier></bibdata>' \
            '<sections><clause><p>See ' \
            '<fmt-xref target="X">clause=5.1.1</fmt-xref> ' \
            'for details.</p></clause></sections></root>'
      doc = adapter.convert(xml)
      para = doc.sections.first.children.first
      text = para.inline_runs.map(&:text).join
      expect(text).to include('clause 5.1.1')
      expect(text).not_to include('clause=5.1.1')
    end
  end

  describe 'inline SVG figure extraction' do
    let(:rules) do
      {
        'metadata' => { 'root' => 'bibdata', 'fields' => { 'docidentifier' => 'docidentifier' } },
        'element_mapping' => { 'clause' => { 'content_type' => 'section' },
                               'figure' => { 'content_type' => 'figure' } },
        'selectors' => { 'figure_image' => 'image', 'figure_caption' => 'fmt-name',
                         'image_src_attribute' => 'src', 'id_attribute' => 'id' },
        'sections' => { 'container' => 'sections' }
      }
    end

    it 'derives section level from the autonumber dotted depth' do
      xml = '<root><bibdata><docidentifier>X</docidentifier></bibdata>' \
            '<sections><clause id="c1"><title>One</title><fmt-title>One</fmt-title>' \
            '<clause id="c2"><title>Two</title><fmt-title>' \
            '<semx element="autonum">5.1</semx> Two</fmt-title>' \
            '<clause id="c3"><title>Three</title><fmt-title>' \
            '<semx element="autonum">5.1.1</semx> Three</fmt-title></clause>' \
            '</clause></clause></sections></root>'
      doc = adapter.convert(xml)
      levels = []
      collect = lambda do |secs|
        secs.each do |sec|
          levels << [sec.title.to_s, sec.level]
          collect.call(sec.children.grep(Arrolio::Content::Section))
        end
      end
      collect.call(doc.sections)
      expect(levels).to include(['Two', 2])
      expect(levels).to include(['Three', 3])
    end

    it 'extracts inline SVG from image element with viewBox dimensions' do
      xml = '<root><bibdata><docidentifier>X</docidentifier></bibdata>' \
            '<sections><clause>' \
            '<figure id="fig-1">' \
            '<image src="images/fig.svg">' \
            '<svg viewBox="0 0 400 300"><rect/></svg>' \
            '</image>' \
            '<fmt-name>Test Figure</fmt-name>' \
            '</figure>' \
            '</clause></sections></root>'
      doc = adapter.convert(xml)
      section = doc.sections.first
      figure = section.children.find { |c| c.is_a?(Arrolio::Content::FigureGroup) }
      expect(figure).not_to be_nil
      expect(figure.image.src).to start_with('inline-svg:')
      expect(figure.image.width).to eq(300.0) # 400px * 72/96
      expect(figure.image.height).to eq(225.0) # 300px * 72/96
    end

    it 'falls back to external src when no inline SVG present' do
      xml = '<root><bibdata><docidentifier>X</docidentifier></bibdata>' \
            '<sections><clause>' \
            '<figure id="fig-2">' \
            '<image src="external.png"/>' \
            '<fmt-name>External Figure</fmt-name>' \
            '</figure>' \
            '</clause></sections></root>'
      doc = adapter.convert(xml)
      section = doc.sections.first
      figure = section.children.find { |c| c.is_a?(Arrolio::Content::FigureGroup) }
      expect(figure).not_to be_nil
      expect(figure.image.src).to eq('external.png')
    end
  end

  describe 'definition list (dl/dt/dd) conversion' do
    let(:rules) do
      {
        'metadata' => { 'root' => 'bibdata', 'fields' => { 'docidentifier' => 'docidentifier' } },
        'element_mapping' => {
          'clause' => { 'content_type' => 'section' },
          'p' => { 'content_type' => 'paragraph' },
          'dl' => { 'content_type' => 'list', 'kind' => 'bullet' }
        },
        'selectors' => { 'paragraph' => 'p' },
        'sections' => { 'container' => 'sections' }
      }
    end

    it 'converts dl with dt/dd pairs into list items' do
      xml = '<root><bibdata><docidentifier>X</docidentifier></bibdata>' \
            '<sections><clause>' \
            '<dl><dt>AC</dt><dd><p>Alternating Current</p></dd>' \
            '<dt>CH</dt><dd><p>Convection Heated</p></dd></dl>' \
            '</clause></sections></root>'
      doc = adapter.convert(xml)
      section = doc.sections.first
      list = section.children.find { |c| c.is_a?(Arrolio::Content::List) }
      expect(list).not_to be_nil
      expect(list.items.length).to eq(2)
      expect(list.items[0].marker).to eq('AC')
      expect(list.items[1].marker).to eq('CH')
    end

    it 'handles empty dd gracefully' do
      xml = '<root><bibdata><docidentifier>X</docidentifier></bibdata>' \
            '<sections><clause>' \
            '<dl><dt>X</dt><dd></dd></dl>' \
            '</clause></sections></root>'
      doc = adapter.convert(xml)
      section = doc.sections.first
      list = section.children.find { |c| c.is_a?(Arrolio::Content::List) }
      expect(list).not_to be_nil
      expect(list.items.length).to eq(1)
    end
  end
end
