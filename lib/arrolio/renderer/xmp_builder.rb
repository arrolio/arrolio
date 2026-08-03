# frozen_string_literal: true

module Arrolio
  module Renderer
    # Builds an XMP metadata packet (RDF/XML wrapped in xpacket
    # processing instructions). XMP carries Dublin Core properties
    # (dc:title, dc:creator) alongside PDF-specific properties
    # (pdf:Producer, xmp:CreatorTool). The packet is stored as a
    # stream on the PDF catalog's /Metadata entry.
    class XmpBuilder
      XPACKET_BEGIN = '<?xpacket begin="\xEF\xBB\xBF" id="W5M0MpCehiHzreSzNTczkc9d"?>'
      XPACKET_END = '<?xpacket end="w"?>'

      attr_reader :metadata

      def initialize(metadata = {})
        @metadata = metadata
      end

      def build
        [XPACKET_BEGIN, xmp_body, XPACKET_END].join("\n")
      end

      private

      def xmp_body
        %(<x:xmpmeta xmlns:x="adobe:ns:meta/">) +
          %(<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">) +
          rdf_descriptions +
          %(</rdf:RDF>) +
          %(</x:xmpmeta>)
      end

      def rdf_descriptions
        [dc_description, pdf_description, xmp_description].compact.join
      end

      def dc_description
        return '' unless @metadata[:title] || @metadata[:author]

        inner = []
        if @metadata[:title]
          inner << (%(<dc:title><rdf:Alt><rdf:li xml:lang="x-default">) +
                    escape(@metadata[:title].to_s) +
                    %(</rdf:li></rdf:Alt></dc:title>))
        end
        if @metadata[:author]
          inner << (%(<dc:creator><rdf:Seq><rdf:li>) +
                    escape(@metadata[:author].to_s) +
                    %(</rdf:li></rdf:Seq></dc:creator>))
        end
        %(<rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">) +
          inner.join +
          %(</rdf:Description>)
      end

      def pdf_description
        producer = escape(@metadata[:producer] || 'Arrolio + Pdfrb')
        %(<rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">) +
          %(<pdf:Producer>) + producer + %(</pdf:Producer>) +
          %(</rdf:Description>)
      end

      def xmp_description
        creator_tool = escape(@metadata[:creator_tool] || 'Arrolio (Ruby)')
        create_date = xmp_date(@metadata[:created_at])
        modify_date = xmp_date(@metadata[:modified_at])
        %(<rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/">) +
          %(<xmp:CreatorTool>) + creator_tool + %(</xmp:CreatorTool>) +
          (create_date ? %(<xmp:CreateDate>) + create_date + %(</xmp:CreateDate>) : '') +
          (modify_date ? %(<xmp:ModifyDate>) + modify_date + %(</xmp:ModifyDate>) : '') +
          %(</rdf:Description>)
      end

      def xmp_date(time)
        t = time || Time.now
        t = Time.parse(t.to_s) unless t.is_a?(Time)
        t.strftime('%Y-%m-%dT%H:%M:%S%:z')
      rescue StandardError
        nil
      end

      def escape(str)
        str.to_s
           .gsub('&', '&amp;')
           .gsub('<', '&lt;')
           .gsub('>', '&gt;')
           .gsub('"', '&quot;')
      end
    end
  end
end
