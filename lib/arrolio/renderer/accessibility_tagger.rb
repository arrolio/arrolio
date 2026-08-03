# frozen_string_literal: true

module Arrolio
  module Renderer
    # Builds marked-content property lists for PDF/UA accessibility.
    # Wraps non-text content (images, formulas) with /Alt and
    # /ActualText entries so screen readers can access the semantic
    # meaning even when the visual rendering is a rasterized image
    # or a flattened formula.
    #
    # In the PDF content stream, marked content looks like:
    #   /MP << /Alt (alternative text) >> BDC
    #   ... drawing operators ...
    #   EMC
    #
    # This class builds the property list dictionaries; the renderer
    # wraps them in BDC/EMC operators when drawing.
    class AccessibilityTagger
      attr_reader :document

      def initialize(document)
        @document = document
        @sequence = 0
      end

      # Builds a property list dictionary for an image's alt text.
      # Returns a Pdfrb reference to the dictionary, or nil if no
      # alt text is provided.
      def alt_property(alt_text)
        return nil if alt_text.nil? || alt_text.to_s.empty?

        @document.add(
          { Alt: alt_text.to_s },
          type: Pdfrb::Model::Cos::Dictionary
        )
      end

      # Builds a property list for actual text (the visible text
      # representation of non-text content, e.g. a formula's
      # flattened text).
      def actual_text_property(text)
        return nil if text.nil? || text.to_s.empty?

        @document.add(
          { ActualText: text.to_s },
          type: Pdfrb::Model::Cos::Dictionary
        )
      end

      # Combines alt + actual text into a single property list.
      # When both are present, the dictionary carries both entries.
      def combined_property(alt_text: nil, actual_text: nil)
        props = {}
        props[:Alt] = alt_text.to_s if alt_text && !alt_text.to_s.empty?
        props[:ActualText] = actual_text.to_s if actual_text && !actual_text.to_s.empty?
        return nil if props.empty?

        @document.add(props, type: Pdfrb::Model::Cos::Dictionary)
      end

      # Next unique marked-content sequence number. Used by the
      # renderer to tag BDC/EMC pairs so structure-tree entries can
      # reference them.
      def next_tag
        @sequence += 1
        :"MC#{@sequence}"
      end
    end
  end
end
