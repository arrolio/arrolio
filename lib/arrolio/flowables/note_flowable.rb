# frozen_string_literal: true

module Arrolio
  module Flowables
    # Note / example callout: italic label in marker column, body
    # indented. Reuses ListFlowable's hanging-indent infrastructure.
    class NoteFlowable < ListFlowable
      def initialize(label_text, body_flowables, style: Style::Definition.new,
                     marker_width: 22.0, body_indent: 6.0, label_style: nil)
        effective_label_style = label_style || style.with(font_size: style.font_size)
        marker_run = InlineRun.new("#{label_text} ", style: effective_label_style)
        marker_flow = TextFlowable.new([marker_run], style: effective_label_style)
        super([[marker_flow, body_flowables]],
              kind: :note, style: style,
              marker_width: marker_width, body_indent: body_indent)
      end

      # NoteFlowable wraps a single (marker, body) pair. Don't split
      # it via ListFlowable#do_split — that path rebuilds via
      # self.class.new(items, ...) which doesn't match NoteFlowable's
      # constructor signature. Keep the note intact; if it doesn't
      # fit, push the whole note to the next page.
      def do_split(width, remaining_height, context = nil)
        total = height(width, context)
        if total <= remaining_height
          [self, nil]
        else
          [nil, self]
        end
      end
    end
  end
end
