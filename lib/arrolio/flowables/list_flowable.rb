# frozen_string_literal: true

module Arrolio
  module Flowables
    # Hanging-indent list. Each item has a marker column (fixed
    # width) and a body column (wraps under body, not marker).
    class ListFlowable < Flowable
      attr_reader :items, :kind, :marker_width, :body_indent

      def initialize(items, kind: :bullet, style: Style::Definition.new,
                     marker_width: 18.0, body_indent: 6.0)
        super(style: style)
        @kind = kind.to_sym
        @marker_width = marker_width.to_f
        @body_indent = body_indent.to_f
        @items = items
        freeze
      end

      def height(width, context = nil)
        @items.sum do |item|
          _, body_flowables = item
          body_width = width - @marker_width - @body_indent
          body_flowables.sum { |f| f.height(body_width, context) }
        end
      end

      def emit(x, y, width, context = nil)
        boxes = []
        consumed = 0.0
        cursor = y
        body_x = x + @marker_width + @body_indent
        body_width = width - @marker_width - @body_indent

        @items.each_with_index do |item, idx|
          marker_text, body_flowables = item
          marker = marker_text || default_marker(idx)

          if marker.is_a?(String)
            if marker.empty?
              # no marker to draw
            else
              mboxes, = marker_flowable(marker, x, cursor, width, context).emit(x, cursor, width, context)
              boxes.concat(mboxes)
            end
          elsif marker
            # marker is a Flowable (e.g. NoteFlowable passes a TextFlowable)
            mboxes, = marker.emit(x, cursor, width, context)
            boxes.concat(mboxes)
          end

          body_flowables.each do |f|
            fh = f.height(body_width, context)
            fboxes, = f.emit(body_x, cursor, body_width, context)
            boxes.concat(fboxes)
            cursor -= fh
            consumed += fh
          end
        end

        [boxes, consumed]
      end

      def splittable?
        true
      end

      def do_split(width, remaining_height, context = nil)
        head_items = []
        tail_items = []
        used = 0.0

        @items.each do |item|
          _, body_flowables = item
          item_h = body_flowables.sum { |f| f.height(width - @marker_width - @body_indent, context) }
          if used + item_h <= remaining_height || head_items.empty?
            head_items << item
            used += item_h
          else
            tail_items << item
          end
        end

        head = if head_items.empty?
  nil
else
  self.class.new(head_items, kind: @kind, style: @style,
                             marker_width: @marker_width,
                             body_indent: @body_indent)
end
        tail = if tail_items.empty?
  nil
else
  self.class.new(tail_items, kind: @kind, style: @style,
                             marker_width: @marker_width,
                             body_indent: @body_indent)
end
        [head, tail]
      end

      private

      def default_marker(idx)
        case @kind
        when :ordered then "#{idx + 1}."
        when :bullet then "\u25A0"
        else "\u2022"
        end
      end

      def marker_flowable(text, _x, _y, _w, _ctx)
        marker_style = @style.with(font_size: @style.font_size * 0.6)
        TextFlowable.new([InlineRun.new(text, style: marker_style)], style: marker_style)
      end
    end
  end
end
