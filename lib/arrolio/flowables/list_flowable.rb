# frozen_string_literal: true

module Arrolio
  module Flowables
    # Hanging-indent list. Each item has a marker column (fixed
    # width) and a body column (wraps under body, not marker).
    class ListFlowable < Flowable
      attr_reader :items, :kind, :marker_width, :body_indent,
                  :marker_indent, :item_spacing

      def initialize(items, kind: :bullet, style: Style::Definition.new,
                     marker_width: 18.0, body_indent: 6.0,
                     marker_indent: 0.0, item_spacing: 0.0)
        super(style: style)
        @kind = kind.to_sym
        @marker_width = marker_width.to_f
        @body_indent = body_indent.to_f
        @marker_indent = marker_indent.to_f
        @item_spacing = item_spacing.to_f
        @items = items
        freeze
      end

      def height(width, context = nil)
        body_h = @items.sum do |item|
          _, body_flowables = item
          body_flowables.sum { |f| f.height(body_width(width), context) }
        end
        body_h + ([@items.length - 1, 0].max * @item_spacing)
      end

      # What must stay with a preceding keep-with-next flowable:
      # the first item — the lead-in paragraph keeps with the
      # list's first line, not the whole list.
      def min_keep_height(width, context = nil)
        _, body_flowables = @items.first
        return 0.0 unless body_flowables&.any?

        body_flowables.sum { |f| f.height(body_width(width), context) }
      end

      def emit(x, y, width, context = nil)
        boxes = []
        consumed = 0.0
        cursor = y
        marker_x = x + @marker_indent
        body_x = x + @marker_indent + @marker_width + @body_indent

        @items.each_with_index do |item, idx|
          marker_text, body_flowables = item
          marker = marker_text || default_marker(idx)

          if marker.is_a?(String)
            unless marker.empty?
              mboxes, = marker_flowable(marker, marker_x, cursor, width, context)
                                 .emit(marker_x, cursor, width, context)
              boxes.concat(mboxes)
            end
          elsif marker
            # marker is a Flowable (e.g. NoteFlowable passes a TextFlowable)
            mboxes, = marker.emit(marker_x, cursor, width, context)
            boxes.concat(mboxes)
          end

          item_h = 0.0
          body_flowables.each do |f|
            fh = f.height(body_width(width), context)
            fboxes, = f.emit(body_x, cursor, body_width(width), context)
            boxes.concat(fboxes)
            cursor -= fh
            item_h += fh
          end

          if idx < @items.length - 1 && @item_spacing.positive?
            cursor -= @item_spacing
            item_h += @item_spacing
          end
          consumed += item_h
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
          item_h = body_flowables.sum { |f| f.height(body_width(width), context) }
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
                             body_indent: @body_indent,
                             marker_indent: @marker_indent,
                             item_spacing: @item_spacing)
end
        tail = if tail_items.empty?
  nil
else
  self.class.new(tail_items, kind: @kind, style: @style,
                             marker_width: @marker_width,
                             body_indent: @body_indent,
                             marker_indent: @marker_indent,
                             item_spacing: @item_spacing)
end
        [head, tail]
      end

      private

      def body_width(width)
        width - @marker_indent - @marker_width - @body_indent
      end

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
