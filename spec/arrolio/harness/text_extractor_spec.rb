# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'tmpdir'

RSpec.describe Arrolio::Harness::TextExtractor do
  # The extractor underpins the parity metric; its contract is
  # pinned against a PDF rendered by the project's own pipeline
  # (previously these specs silently skipped unless a stray
  # spec/out.pdf happened to exist).
  let(:pdf_path) do
    layout = Arrolio::LayoutSpec::Loader.load(<<~YAML)
      default_page_template: body
      page_templates:
        body: { page_size: A4, margins: { all: 50 } }
      styles:
        body: { font_name: Times-Roman, font_size: 11 }
    YAML
    style = layout.resolve_style(:body)
    flowables = [
      Arrolio::Flowables::TextFlowable.new(
        [Arrolio::InlineRun.new('alpha beta gamma', style: style)],
        style: style
      ),
      Arrolio::Flowables::TextFlowable.new(
        [Arrolio::InlineRun.new('delta epsilon', style: style)],
        style: style
      )
    ]
    pages = Arrolio::Engine::Paged.new(layout_spec: layout, flowables: flowables).layout
    path = File.join(Dir.mktmpdir, 'extractor.pdf')
    File.open(path, 'wb') do |f|
      Arrolio::Renderer::Pdf.new.render(pages, io: f)
    end
    path
  end

  describe '#pages' do
    it 'returns an array of page strings' do
      pages = described_class.new(pdf_path).pages
      expect(pages).to be_an(Array)
      expect(pages.length).to eq(1)
      expect(pages.first).to include('alpha')
    end

    it 'returns empty array for non-existent file' do
      ext = described_class.new('/nonexistent/path.pdf')
      expect(ext.pages).to eq([])
    end
  end

  describe '#word_count' do
    it 'counts the rendered words' do
      expect(described_class.new(pdf_path).word_count).to eq(5)
    end
  end
end
