# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::MathML::InlineRunExtractor do
  describe '.extract_from_xml' do
    it 'extracts text from a simple <mi> element' do
      xml = '<math xmlns="http://www.w3.org/1998/Math/MathML"><mi>x</mi></math>'
      runs = described_class.extract_from_xml(xml)
      expect(runs.length).to be >= 1
      expect(runs.first.text).to eq('x')
      expect(runs.first.style_id).to eq(:math_identifier)
    end

    it 'extracts subscripts from <msub>' do
      xml = <<~XML
        <math xmlns="http://www.w3.org/1998/Math/MathML">
          <mrow><msub><mi>v</mi><mtext>min</mtext></msub></mrow>
        </math>
      XML
      runs = described_class.extract_from_xml(xml)
      texts = runs.map(&:text)
      expect(texts).to include('v')
      expect(texts).to include('min')
      sub_run = runs.find { |r| r.text == 'min' }
      expect(sub_run.baseline_shift).to eq(Arrolio::Content::InlineRun::BASELINE_SUB)
      expect(sub_run.font_size_scale).to be < 1.0
    end

    it 'extracts superscripts from <msup>' do
      xml = <<~XML
        <math xmlns="http://www.w3.org/1998/Math/MathML">
          <mrow><msup><mi>x</mi><mn>2</mn></msup></mrow>
        </math>
      XML
      runs = described_class.extract_from_xml(xml)
      texts = runs.map(&:text)
      expect(texts).to include('x')
      expect(texts).to include('2')
      sup_run = runs.find { |r| r.text == '2' }
      expect(sup_run.baseline_shift).to eq(Arrolio::Content::InlineRun::BASELINE_SUP)
    end

    it 'extracts both sub and sup from <msubsup>' do
      xml = <<~XML
        <math xmlns="http://www.w3.org/1998/Math/MathML">
          <mrow><msubsup><mi>x</mi><mn>1</mn><mn>2</mn></msubsup></mrow>
        </math>
      XML
      runs = described_class.extract_from_xml(xml)
      texts = runs.map(&:text)
      expect(texts).to include('x')
      expect(texts).to include('1')
      expect(texts).to include('2')
      sub = runs.find { |r| r.text == '1' }
      sup = runs.find { |r| r.text == '2' }
      expect(sub.baseline_shift).to eq(Arrolio::Content::InlineRun::BASELINE_SUB)
      expect(sup.baseline_shift).to eq(Arrolio::Content::InlineRun::BASELINE_SUP)
    end

    it 'handles <mn> and <mo> elements' do
      xml = <<~XML
        <math xmlns="http://www.w3.org/1998/Math/MathML">
          <mrow><mi>a</mi><mo>+</mo><mn>1</mn></mrow>
        </math>
      XML
      runs = described_class.extract_from_xml(xml)
      texts = runs.map(&:text)
      expect(texts).to include('a')
      expect(texts).to include('+')
      expect(texts).to include('1')
    end

    it 'handles <mfrac> by emitting numerator/denominator inline' do
      xml = <<~XML
        <math xmlns="http://www.w3.org/1998/Math/MathML">
          <mfrac><mi>a</mi><mi>b</mi></mfrac>
        </math>
      XML
      runs = described_class.extract_from_xml(xml)
      texts = runs.map(&:text)
      expect(texts).to include('a')
      expect(texts).to include('/')
      expect(texts).to include('b')
    end

    it 'returns empty array for nil or empty input' do
      expect(described_class.extract_from_xml(nil)).to eq([])
      expect(described_class.extract_from_xml('')).to eq([])
    end

    it 'returns empty array for invalid MathML' do
      runs = described_class.extract_from_xml('<not-mathml/>')
      expect(runs).to eq([])
    end

    it 'uses custom base_style when provided' do
      xml = '<math xmlns="http://www.w3.org/1998/Math/MathML"><mn>42</mn></math>'
      runs = described_class.extract_from_xml(xml, base_style: :formula)
      mn_run = runs.find { |r| r.text == '42' }
      expect(mn_run.style_id).to eq(:formula)
    end
  end

  describe '#extract' do
    it 'walks a parsed Mml::V3::Math tree directly' do
      math_xml = <<~XML
        <math xmlns="http://www.w3.org/1998/Math/MathML">
          <mstyle><msub><mi>E</mi><mtext>max</mtext></msub></mstyle>
        </math>
      XML
      parsed = Mml.parse(math_xml, version: 3)
      extractor = described_class.new(base_style: :math)
      runs = extractor.extract(parsed)
      texts = runs.map(&:text)
      expect(texts).to include('E')
      expect(texts).to include('max')
    end
  end
end
