# frozen_string_literal: true

module Arrolio
  module Output
    class PlacedBox
      attr_reader :x, :y, :width, :height, :kind, :data, :link_dest

      def initialize(x:, y:, width:, height:, kind:, data: {}, link_dest: nil)
        @x = x.to_f
        @y = y.to_f
        @width = width.to_f
        @height = height.to_f
        @kind = kind
        @data = data.to_h.freeze
        @link_dest = link_dest
        freeze
      end

      class << self
        def text(x:, y:, width:, height:, lines:, line_height:, style:, link_dest: nil)
          new(x: x, y: y, width: width, height: height, kind: :text,
              data: { lines: Array(lines).freeze,
                      line_height: line_height.to_f,
                      style: style },
              link_dest: link_dest)
        end

        def rect(x:, y:, width:, height:, stroke_width: 0.5,
                 stroke_color: nil, fill_color: nil)
          new(x: x, y: y, width: width, height: height, kind: :rect,
              data: { stroke_width: stroke_width.to_f,
                      stroke_color: stroke_color,
                      fill_color: fill_color })
        end

        def line(x1:, y1:, x2:, y2:, stroke_width: 0.5, stroke_color: nil)
          new(x: [x1, x2].min, y: [y1, y2].min,
              width: (x2 - x1).abs, height: (y2 - y1).abs,
              kind: :line,
              data: { x1: x1.to_f, y1: y1.to_f,
                      x2: x2.to_f, y2: y2.to_f,
                      stroke_width: stroke_width.to_f,
                      stroke_color: stroke_color })
        end

        def image(x:, y:, width:, height:, image_ref:, link_dest: nil)
          new(x: x, y: y, width: width, height: height, kind: :image,
              data: { image_ref: image_ref },
              link_dest: link_dest)
        end
      end

      def ==(other)
        other.is_a?(self.class) &&
          x == other.x && y == other.y &&
          width == other.width && height == other.height &&
          kind == other.kind && data == other.data &&
          link_dest == other.link_dest
      end

      alias eql? ==

      def hash
        [self.class, x, y, width, height, kind, data, link_dest].hash
      end
    end
  end
end
