# frozen_string_literal: true

module Arrolio
  module Renderer
    # Collects hyperlink annotations during rendering and emits them
    # as /Annot entries on each PDF page. The renderer calls
    # +record_link+ for each text run that has an href; after the
    # page is fully rendered, +flush+ emits the /Annots array.
    class LinkAnnotator
      Link = Struct.new(:x, :y, :width, :height, :uri, keyword_init: true)

      attr_reader :document, :pending_links

      def initialize(document)
        @document = document
        @pending_links = []
      end

      def record_link(x:, y:, width:, height:, uri:)
        @pending_links << Link.new(x: x, y: y, width: width, height: height, uri: uri)
      end

      # Emits collected links as /Annot entries on the given pdfrb
      # page. Clears the pending list after emitting.
      def flush(pdfrb_page)
        return if @pending_links.empty?

        annots = @pending_links.map { |link| build_link_annot(link) }
        existing = pdfrb_page.value[:Annots]
        if existing.is_a?(Array)
          existing.concat(annots)
        else
          pdfrb_page.value[:Annots] = annots
        end
        @pending_links.clear
      end

      private

      def build_link_annot(link)
        rect = [
          link.x,
          link.y,
          link.x + link.width,
          link.y + link.height
        ]
        action = @document.add(
          { S: :URI, URI: link.uri },
          type: Pdfrb::Model::Cos::Dictionary
        )
        annot = @document.add(
          { Type: :Annot, Subtype: :Link,
            Rect: rect,
            Border: [0, 0, 0],
            A: Pdfrb::Model::Reference.new(action.oid, action.gen) },
          type: Pdfrb::Model::Cos::Dictionary
        )
        Pdfrb::Model::Reference.new(annot.oid, annot.gen)
      end
    end
  end
end
