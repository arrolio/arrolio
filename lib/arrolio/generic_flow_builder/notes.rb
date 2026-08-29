# frozen_string_literal: true

module Arrolio
  class GenericFlowBuilder
    # Extracted emission seam: one module per content family, the
    # same pattern as GenericAdapter's decomposition. The class
    # keeps build(), dispatch, and shared helpers.
    module Notes
      def note_flowable(note)
        body = note.body.map { |node| note_body_flowable(node) }
        body = with_note_body_spacing(body)
        Flowables::NoteFlowable.new(
          formatted_note_label(note.label),
          body,
          style: resolve(note.style_id),
          label_style: resolve(:note_label)
        )
      end

      # A note's trailing list sits ~7pt below its text in the
      # reference (3.1.3.1: text -> list 20pt vs a plain 13pt pitch).
      def with_note_body_spacing(body)
        spacing = (@rules.dig('note', 'body_spacing') || 0.0).to_f
        return body if spacing.zero? || body.length < 2

        body.flat_map.with_index do |flowable, index|
          index < body.length - 1 ? [flowable, Flowables::Spacer.new(spacing)] : [flowable]
        end
      end

      def note_body_flowable(node)
        return list_flowable(node, container: :note) if node.is_a?(Content::List)

        paragraph_flowable(node)
      end

      def formatted_note_label(label)
        return '' if label.nil? || label.empty?

        suffix = @rules.dig('note', 'label_suffix') || ':'
        stripped = label.strip.chomp(':').strip
        return '' if stripped.empty?

        suffix.start_with?(':') ? "#{stripped}#{suffix} " : "#{stripped} #{suffix} "
      end

      # Examples render the label as a block heading with the body
      # indented 35.4pt — the FOP example layout.
      def example_flowable(example)
        body = example.body.map { |paragraph| paragraph_flowable(paragraph) }
        Flowables::NoteFlowable.new(
          example.label,
          body,
          style: resolve(example.style_id),
          body_indent: 35.4,
          label_mode: :block
        )
      end
    end
  end
end
