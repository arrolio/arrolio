# frozen_string_literal: true

require 'spec_helper'

# The MathML adapter's first direct test surface: presentation
# MathML in, InlineRun[] out (text, style_id, baseline_shift,
# font_size_scale). Every shape below appears in the OIML
# reference document, so this spec pins the contract the layout
# depends on — subscripts render as scaled, shifted runs;
# operators survive as text; parse failures return [].
RSpec.describe Arrolio::MathML::InlineRunExtractor do
  def extract(mathml_body)
    xml = %(<math xmlns="http://www.w3.org/1998/Math/MathML">#{mathml_body}</math>)
    described_class.extract_from_xml(xml, base_style: :inline)
  end

  def joined(runs)
    runs.map(&:text).join
  end

  it 'extracts a subscripted identifier as base + shifted, scaled run' do
    runs = extract('<msub><mi>n</mi><mtext>LC</mtext></msub>')
    expect(joined(runs)).to include('n')
    expect(joined(runs)).to include('LC')
    sub = runs.find { |r| r.text.include?('LC') }
    expect(sub.baseline_shift).to eq(:sub)
    expect(sub.font_size_scale).to be < 1.0
  end

  it 'keeps relational operators as text' do
    runs = extract('<mi>p</mi><mo>\u2264</mo><mn>0.8</mn>')
    text = joined(runs)
    expect(text).to include('p')
    expect(text).to include('\u2264')
    expect(text).to include('0.8')
  end

  it 'extracts unit mtext content' do
    runs = extract('<mi>2</mi><mtext>\u00b0C</mtext>')
    expect(joined(runs)).to include('2')
    expect(joined(runs)).to include('\u00b0C')
  end

  it 'marks identifiers with the math_identifier style' do
    runs = extract('<mi>n</mi>')
    ident = runs.find { |r| r.text.include?('n') }
    expect(ident.style_id).to eq(:math_identifier)
  end

  it 'returns [] for unparseable input without raising' do
    expect(described_class.extract_from_xml('<not-math')).to eq([])
    expect(described_class.extract_from_xml('')).to eq([])
    expect(described_class.extract_from_xml(nil)).to eq([])
  end

  it 'emits runs in document order' do
    runs = extract('<mi>a</mi><mi>b</mi><mi>c</mi>')
    expect(joined(runs)).to eq('abc')
  end
end
