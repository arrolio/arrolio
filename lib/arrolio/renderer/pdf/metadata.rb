# frozen_string_literal: true

module Arrolio
  module Renderer
    class Pdf
      # Extracted concern: Pdfrb coupling points kept out of the
      # emission path.
      module Metadata
        def apply_metadata(metadata)
          info = @document.catalog.value[:Info]
          info ||= @document.add({})
          @document.catalog.value[:Info] = info
          info.value[:Title] = metadata[:title] if metadata[:title]
          info.value[:Author] = metadata[:author] if metadata[:author]
          info.value[:Creator] = 'Arrolio (Ruby)'
          info.value[:Producer] = 'Arrolio + Pdfrb'
        end

        # Emit an XMP metadata packet (RDF/XML) as a stream on the
        # catalog's /Metadata entry. PDF readers use this for Dublin
        # Core properties alongside the legacy /Info dict.
        def attach_xmp_metadata(metadata)
          xmp = XmpBuilder.new(metadata).build
          stream = @document.add(
            { Type: :Metadata, Subtype: :XML, Length: xmp.bytesize },
            type: Pdfrb::Model::Cos::Stream
          )
          stream.stream = xmp
          @document.catalog.value[:Metadata] =
            Pdfrb::Model::Reference.new(stream.oid, stream.gen)
        rescue StandardError => e
          Arrolio::Logger.warn "XMP attach failed: #{e.class}: #{e.message[0, 80]}"
        end

        def build_outline(context, _pages)
          entries = context.heading_entries
          return unless entries&.any?

          pdfrb_pages = @document.pages.to_a
          ob = OutlineBuilder.new(document: @document,
                                  entries: entries,
                                  pdfrb_pages: pdfrb_pages)
          result = ob.build
          Arrolio::Logger.debug "outline build returned: #{result.class}"
        rescue StandardError => e
          Arrolio::Logger.warn "outline build failed: #{e.class}: #{e.message[0,150]}"
          Arrolio::Logger.debug e.backtrace.first(5).join("\n")
        end
      end
    end
  end
end
