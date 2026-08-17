# frozen_string_literal: true

module Arrolio
  module Flowables
    # Note / example callout. Two label layouts:
    #
    # - :hanging (notes) — italic label in the marker column, body
    #   wraps on the same first line (hanging indent). Implemented on
    #   ListFlowable's hanging-indent infrastructure.
    # - :block (examples) — the label is a heading on its own line
    #   at the column edge ("Example:"), body flows below it indented
    #   by +body_indent+. Emitted sequentially: the label line's
    #   height is part of the flow, so page breaking sees the whole
    #   block.
    class NoteFlowable < ListFlowable
      BLOCK_LABEL_GAP = 6.0

      attr_reader :label_mode

      def initialize(label_text, body_flowables, style: Style::Definition.new,
                     marker_width: 22.0, body_indent: 6.0, label_style: nil,
                     label_mode: :hanging)
        @label_mode = label_mode.to_sym
        effective_label_style = label_style || style.with(font_size: style.font_size)
        if @label_mode == :block
          @block_label = TextFlowable.new(
            [InlineRun.new("#{label_text}:", style: effective_label_style)],
            style: effective_label_style
          )
          @block_body = Array(body_flowables)
          @block_indent = body_indent.to_f
          super([[nil, []]], kind: :note, style: style)
        else
          marker_run = InlineRun.new("#{label_text} ", style: effective_label_style)
          marker_flow = TextFlowable.new([marker_run], style: effective_label_style)
          super([[marker_flow, Array(body_flowables)]],
                kind: :note, style: style,
                marker_width: marker_width, body_indent: body_indent)
        end
      end

      def height(width, context = nil)
        return block_height(width, context) if @label_mode == :block

        super
      end

      def emit(x, y, width, context = nil)
        return block_emit(x, y, width, context) if @label_mode == :block

        super
      end

      # Notes stay intact across page breaks: if the whole note does
      # not fit, it moves to the next page. ListFlowable#do_split is
      # not usable here — it rebuilds via self.class.new(items, ...)
      # which does not match this constructor's signature.
      def do_split(width, remaining_height, context = nil)
        total = height(width, context)
        if total <= remaining_height
          [self, nil]
        else
          [nil, self]
        end
      end

      private

      def block_height(width, context = nil)
        @block_label.height(width, context) + BLOCK_LABEL_GAP +
          @block_body.sum { |f| f.height(width - @block_indent, context) }
      end

      def block_emit(x, y, width, context = nil)
        boxes = []
        consumed = 0.0
        cursor = y

        label_boxes, label_h = @block_label.emit(x, cursor, width, context)
        boxes.concat(label_boxes)
        cursor -= label_h + BLOCK_LABEL_GAP
        consumed += label_h + BLOCK_LABEL_GAP

        @block_body.each do |flow|
          fboxes, fh = flow.emit(x + @block_indent, cursor, width - @block_indent, context)
          boxes.concat(fboxes)
          cursor -= fh
          consumed += fh
        end
        [boxes, consumed]
      end
    end
  end
end
