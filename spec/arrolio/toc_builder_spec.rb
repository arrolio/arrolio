# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::TocBuilder do
  let(:flavor_dir) { File.expand_path('../fixtures/flavors/sample', __dir__) }
  let(:layout_spec) { Arrolio::LayoutSpec::Loader.load(File.join(flavor_dir, 'layout_spec.yml')) }

  def context_with(*entries)
    context = Arrolio::FlowContext.new(layout_spec: layout_spec)
    entries.each { |e| context.record_heading(**e) }
    context
  end

  it 'composes the label from number and title' do
    context = context_with({ number: '3', title: 'Terminology', level: 1, page_number: 7 })
    lines = described_class.build_flowables(context, layout_spec)
    expect(lines.length).to eq(1)
    expect(lines.first.title).to eq('3 Terminology')
    expect(lines.first.page_number).to eq(7)
  end

  it 'uses the bare title when the entry has no number' do
    context = context_with({ number: nil, title: 'Foreword', level: 1, page_number: 4 })
    lines = described_class.build_flowables(context, layout_spec)
    expect(lines.first.title).to eq('Foreword')
  end

  it 'maps level 1 to the entry style and level >= 2 to the sub style' do
    context = context_with(
      { number: '1', title: 'One', level: 1, page_number: 2 },
      { number: '5.1', title: 'Nested', level: 2, page_number: 9 },
      { number: '5.1.2', title: 'Deeper', level: 3, page_number: 11 }
    )
    lines = described_class.build_flowables(context, layout_spec)
    expect(lines.map(&:style).map(&:font_size)).to all(be_positive)
    expect(described_class.style_id_for(1, {})).to eq(:toc_entry)
    expect(described_class.style_id_for(2, {})).to eq(:toc_entry_sub)
    expect(described_class.style_id_for(3, {})).to eq(:toc_entry_sub)
  end

  it 'honors style overrides from the toc rules' do
    expect(described_class.style_id_for(1, { 'entry' => 'custom' })).to eq(:custom)
    expect(described_class.style_id_for(2, { 'sub' => 'custom_sub' })).to eq(:custom_sub)
  end
end
