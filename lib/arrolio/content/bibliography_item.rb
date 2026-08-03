# frozen_string_literal: true

module Arrolio
  module Content
    # A single bibliography entry: citation tag (e.g. "[Smith2020]")
    # and a formatted reference Paragraph. Renders with a
    # hanging-indent so wrapped lines align under the text, not the
    # citation tag.
    class BibliographyItem
      attr_reader :tag, :formattedref, :id, :style_id

      def initialize(formattedref:, tag: nil, id: nil, style_id: :bibitem)
        @tag = tag
        @formattedref = formattedref
        @id = id&.to_s
        @style_id = style_id.to_sym
        freeze
      end

      def text
        @formattedref.is_a?(Paragraph) ? @formattedref.text : @formattedref.to_s
      end

      def empty?
        @tag.nil? && (@formattedref.nil? || (@formattedref.is_a?(Paragraph) && @formattedref.empty?))
      end

      def ==(other)
        other.is_a?(self.class) &&
          tag == other.tag &&
          formattedref == other.formattedref &&
          id == other.id &&
          style_id == other.style_id
      end
      alias eql? ==

      def hash
        [self.class, tag, formattedref, id, style_id].hash
      end
    end
  end
end
