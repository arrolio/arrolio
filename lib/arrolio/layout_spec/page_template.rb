# frozen_string_literal: true

module Arrolio
  class LayoutSpec
    # Page geometry template ("fo:simple-page-master" in XSL-FO).
    # Coordinates are PDF-default user space: origin at the
    # bottom-left of the page, +y+ grows upward. Region +y+ is the
    # bottom edge of the region.
    class PageTemplate
      LETTER = [612.0, 792.0].freeze
      A4 = [595.276, 841.89].freeze

      attr_reader :name, :page_size, :margins, :region_extents, :regions

      def initialize(name:, page_size: LETTER, margins: 72, region_extents: {})
        @name = name.to_sym
        @page_size = resolve_page_size(page_size)
        @margins = normalise_margins(margins)
        @region_extents = default_region_extents.merge(region_extents.to_h)
        @regions = compute_regions.freeze
        freeze
      end

      def body_region
        @regions[:body]
      end

      def region(name)
        @regions[name.to_sym]
      end

      def width
        @page_size[0]
      end

      def height
        @page_size[1]
      end

      def ==(other)
        other.is_a?(self.class) &&
          name == other.name &&
          page_size == other.page_size &&
          margins == other.margins &&
          region_extents == other.region_extents
      end

      alias eql? ==

      def hash
        [self.class, name, page_size, margins, region_extents].hash
      end

      private

      def resolve_page_size(spec)
        case spec
        when Symbol, String
          constant = spec.to_s.upcase.to_sym
          self.class.const_defined?(constant, false) ? self.class.const_get(constant) : LETTER
        when Array
          [spec[0].to_f, spec[1].to_f]
        else
          LETTER
        end
      end

      def normalise_margins(m)
        case m
        when Numeric
          { top: m.to_f, right: m.to_f, bottom: m.to_f, left: m.to_f }
        when Hash
          base = m.transform_keys(&:to_sym)
          all = base[:all]
          {
            top: base[:top] || all || 72.0,
            right: base[:right] || all || 72.0,
            bottom: base[:bottom] || all || 72.0,
            left: base[:left] || all || 72.0
          }
        else
          { top: 72.0, right: 72.0, bottom: 72.0, left: 72.0 }
        end
      end

      def default_region_extents
        { before: 0.0, after: 0.0, start: 0.0, end: 0.0 }
      end

      # XSL-FO geometry: the body region is the page content
      # rectangle (page minus page margins). The before/after/start/
      # end extents size the auxiliary regions that sit INSIDE the
      # margins — they never displace the body. Shrinking the body
      # by the extents wasted the whole header/footer strip on
      # every page.
      def compute_regions
        pw = width
        ph = height
        m = @margins
        e = @region_extents
        inner_w = pw - m[:left] - m[:right]
        inner_h = ph - m[:top] - m[:bottom]
        {
          body: Region.new(name: :body,
                           x: m[:left],
                           y: m[:bottom],
                           width: inner_w,
                           height: inner_h),
          before: Region.new(name: :before,
                             x: m[:left],
                             y: ph - m[:top],
                             width: inner_w,
                             height: e[:before]),
          after: Region.new(name: :after,
                            x: m[:left],
                            y: m[:bottom] - e[:after],
                            width: inner_w,
                            height: e[:after]),
          start: Region.new(name: :start,
                            x: m[:left],
                            y: m[:bottom] + e[:after],
                            width: e[:start],
                            height: inner_h),
          end: Region.new(name: :end,
                          x: pw - m[:right] - e[:end],
                          y: m[:bottom] + e[:after],
                          width: e[:end],
                          height: inner_h)
        }
      end
    end
  end
end
