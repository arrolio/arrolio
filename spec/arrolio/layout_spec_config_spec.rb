# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::LayoutSpec do
  describe 'header_footer and cover_logo config' do
    let(:yaml) do
      <<~YAML
        default_page_template: body
        page_templates:
          body:
            page_size: A4
        header_footer:
          margin_top: 30
          margin_bottom: 30
          font_name: Garamond
          font_size: 10.0
          rule_width: 1.0
        cover_logo:
          width_mm: 40
          aspect_ratio: 0.5
          margin_mm: 20
        styles:
          body:
            font_name: Helvetica
        flows:
          main:
            region: body
      YAML
    end

    let(:spec) { described_class::Loader.load(yaml) }

    it 'exposes header_footer_config as a frozen Hash' do
      expect(spec.header_footer_config).to be_a(Hash)
      expect(spec.header_footer_config).to be_frozen
      expect(spec.header_footer_config['font_name']).to eq('Garamond')
      expect(spec.header_footer_config['margin_top']).to eq(30)
      expect(spec.header_footer_config['rule_width']).to eq(1.0)
    end

    it 'exposes cover_logo_config as a frozen Hash' do
      expect(spec.cover_logo_config).to be_a(Hash)
      expect(spec.cover_logo_config).to be_frozen
      expect(spec.cover_logo_config['width_mm']).to eq(40)
      expect(spec.cover_logo_config['aspect_ratio']).to eq(0.5)
    end

    it 'returns empty hashes when not specified' do
      bare = described_class::Loader.load(<<~YAML)
        default_page_template: body
        page_templates:
          body:
            page_size: A4
        styles:
          body:
            font_name: Helvetica
      YAML
      expect(bare.header_footer_config).to eq({})
      expect(bare.cover_logo_config).to eq({})
    end

    it 'exposes header_footer_config consistently across loads' do
      other = described_class::Loader.load(yaml)
      expect(spec.header_footer_config).to eq(other.header_footer_config)
      expect(spec.cover_logo_config).to eq(other.cover_logo_config)
    end
  end
end

RSpec.describe Arrolio::Renderer::Pdf do
  let(:yaml) do
    <<~YAML
      default_page_template: body
      page_templates:
        body:
          page_size: A4
      header_footer:
        margin_top: 30
        margin_bottom: 30
        margin_lr: 24
        header_offset: 5
        footer_offset: 5
        font_name: Garamond
        font_size: 10.0
        rule_width: 1.5
      cover_logo:
        width_mm: 42
        aspect_ratio: 0.5
        margin_mm: 22
      styles:
        body:
          font_name: Helvetica
    YAML
  end

  let(:layout_spec) { Arrolio::LayoutSpec::Loader.load(yaml) }

  it 'reads header_footer values from layout_spec, not hardcoded constants' do
    renderer = described_class.new
    renderer.render([], io: StringIO.new, layout_spec: layout_spec)
    hf = renderer.header_footer_style
    expect(hf[:margin_top]).to eq(30 * described_class::MM_TO_PT)
    expect(hf[:margin_bottom]).to eq(30 * described_class::MM_TO_PT)
    expect(hf[:margin_lr]).to eq(24 * described_class::MM_TO_PT)
    expect(hf[:header_offset]).to eq(5 * described_class::MM_TO_PT)
    expect(hf[:footer_offset]).to eq(5 * described_class::MM_TO_PT)
    expect(hf[:font_name]).to eq('Garamond')
    expect(hf[:font_size]).to eq(10.0)
    expect(hf[:rule_width]).to eq(1.5)
  end

  it 'reads cover_logo dimensions from layout_spec' do
    renderer = described_class.new
    renderer.render([], io: StringIO.new, layout_spec: layout_spec)
    cl = renderer.cover_logo_style
    expect(cl[:width]).to eq(42 * described_class::MM_TO_PT)
    expect(cl[:margin]).to eq(22 * described_class::MM_TO_PT)
    expect(cl[:height]).to be_within(0.001).of(42 * 0.5 * described_class::MM_TO_PT)
  end

  it 'falls back to engine defaults when layout_spec is nil' do
    renderer = described_class.new
    renderer.render([], io: StringIO.new)
    hf = renderer.header_footer_style
    expect(hf[:font_name]).to eq('Helvetica')
    expect(hf[:margin_top]).to eq(26.5 * described_class::MM_TO_PT)
  end
end
