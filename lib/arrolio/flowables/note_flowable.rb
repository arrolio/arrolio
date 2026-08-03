# frozen_string_literal: true

module Arrolio
  module Flowables
    # Note / example callout: italic label in marker column, body
    # indented. Reuses ListFlowable's hanging-indent infrastructure.
    class NoteFlowable < ListFlowable
      def initialize(label_text, body_flowables, style: Style::Definition.new,
                     marker_width: 22.0, body_indent: 6.0)
        label_style = style.with(font_size: style.font_size)
        marker_run = InlineRun.new("#{label_text} ", style: label_style)
        marker_flow = TextFlowable.new([marker_run], style: label_style)
        super([[marker_flow, body_flowables]],
              kind: :note, style: style,
              marker_width: marker_width, body_indent: body_indent)
      end
    end
  end
end
