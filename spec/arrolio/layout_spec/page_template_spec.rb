# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::LayoutSpec::PageTemplate do
  let(:template) do
    described_class.new(
      name: :body,
      page_size: described_class::A4,
      margins: { top: 75.0, bottom: 75.0, left: 72.0, right: 72.0 },
      region_extents: { before: 51.0, after: 51.0 }
    )
  end

  # XSL-FO: the body region is the page content rectangle (page
  # minus page margins). The before/after extents size the auxiliary
  # regions INSIDE the margins — they never displace the body.
  describe 'body region geometry' do
    it 'spans the full content rectangle regardless of extents' do
      body = template.body_region
      expect(body.x).to eq(72.0)
      expect(body.y).to eq(75.0)
      expect(body.width).to eq(described_class::A4[0] - 144.0)
      expect(body.height).to eq(described_class::A4[1] - 150.0)
    end
  end

  describe 'auxiliary regions' do
    it 'places the before region inside the top margin' do
      ph = described_class::A4[1]
      before = template.region(:before)
      expect(before.height).to eq(51.0)
      expect(before.y).to eq(ph - 75.0)
      expect(before.y + before.height).to be <= ph
    end

    it 'places the after region inside the bottom margin' do
      after = template.region(:after)
      expect(after.height).to eq(51.0)
      expect(after.y).to be >= 0.0
      expect(after.y + after.height).to be <= 75.0
    end
  end

  describe 'equality' do
    it 'compares by name, size, margins, and extents' do
      same = described_class.new(
        name: :body, page_size: described_class::A4,
        margins: { top: 75.0, bottom: 75.0, left: 72.0, right: 72.0 },
        region_extents: { before: 51.0, after: 51.0 }
      )
      other = described_class.new(
        name: :body, page_size: described_class::A4,
        margins: { top: 80.0, bottom: 75.0, left: 72.0, right: 72.0 },
        region_extents: { before: 51.0, after: 51.0 }
      )
      expect(template).to eq(same)
      expect(template).not_to eq(other)
    end
  end
end
