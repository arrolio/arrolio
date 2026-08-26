# frozen_string_literal: true

module Arrolio
  module Flowables
    # A keep-together composite: the whole group moves to the next
    # page when it does not fit the remainder (XSL-FO
    # keep-together). Groups taller than a full page split at child
    # boundaries instead of overflowing.
    class GroupFlowable < Flowable
      attr_reader :parts

      def initialize(parts, style: Style::Definition.new(keep_together: true))
        super(style: style)
        @parts = Array(parts)
      end

      def height(width, context = nil)
        @parts.sum { |p| p.height(width, context) }
      end

      def emit(x, y, width, context = nil)
        boxes = []
        consumed = 0.0
        cursor = y
        @parts.each do |part|
          part_h = part.height(width, context)
          part_boxes, = part.emit(x, cursor, width, context)
          boxes.concat(part_boxes)
          cursor -= part_h
          consumed += part_h
        end
        [boxes, consumed]
      end

      def splittable?
        true
      end

      def do_split(width, remaining_height, context = nil)
        head = []
        tail = []
        used = 0.0
        @parts.each do |part|
          part_h = part.height(width, context)
          if used + part_h <= remaining_height || head.empty?
            head << part
            used += part_h
          else
            tail << part
          end
        end
        [self.class.new(head, style: @style),
         tail.empty? ? nil : self.class.new(tail, style: @style)]
      end
    end
  end
end
