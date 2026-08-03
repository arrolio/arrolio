# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::LayoutSpec::PageTemplateSelector do
  describe 'single template mode' do
    let(:selector) { described_class.new(default_template: :body) }

    it 'returns the default for all pages' do
      expect(selector.name_for(1)).to eq(:body)
      expect(selector.name_for(2)).to eq(:body)
      expect(selector.name_for(99)).to eq(:body)
    end

    it 'is not alternating' do
      expect(selector).not_to be_alternating
    end
  end

  describe 'odd/even mode' do
    let(:selector) do
      described_class.new(default_template: :body,
                          odd_template: :odd_page,
                          even_template: :even_page)
    end

    it 'returns :odd_page for odd page numbers' do
      expect(selector.name_for(1)).to eq(:odd_page)
      expect(selector.name_for(3)).to eq(:odd_page)
      expect(selector.name_for(5)).to eq(:odd_page)
    end

    it 'returns :even_page for even page numbers' do
      expect(selector.name_for(2)).to eq(:even_page)
      expect(selector.name_for(4)).to eq(:even_page)
      expect(selector.name_for(6)).to eq(:even_page)
    end

    it 'is alternating' do
      expect(selector).to be_alternating
    end
  end

  describe 'partial odd/even (only odd configured)' do
    let(:selector) do
      described_class.new(default_template: :body, odd_template: :odd_page)
    end

    it 'uses odd template for odd pages, default for even' do
      expect(selector.name_for(1)).to eq(:odd_page)
      expect(selector.name_for(2)).to eq(:body)
    end

    it 'is alternating' do
      expect(selector).to be_alternating
    end
  end

  it 'is frozen' do
    expect(described_class.new(default_template: :body)).to be_frozen
  end

  it 'compares by value' do
    a = described_class.new(default_template: :body, odd_template: :odd)
    b = described_class.new(default_template: :body, odd_template: :odd)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end
end
