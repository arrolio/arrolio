# frozen_string_literal: true

require 'fontisan'

module Arrolio
  module Font
    class Embedder
      attr_reader :document, :font_path, :base_font_name

      def initialize(document, font_path, base_font_name: nil)
        @document = document
        @font_path = font_path
        @base_font_name = base_font_name || File.basename(font_path, '.*')
        @fontisan_font = Fontisan::FontLoader.load(font_path)
        @unicode_to_gid = @fontisan_font.table('cmap').unicode_mappings.transform_keys(&:to_i)
        @subset_cp_to_gid = nil
        @subset_gid_to_cp = nil
      end

      def glyph_id_for_codepoint(codepoint)
        @unicode_to_gid[codepoint.to_i] || 0
      end

      def subset_gid_for_codepoint(codepoint)
        return glyph_id_for_codepoint(codepoint) unless @subset_cp_to_gid
        @subset_cp_to_gid[codepoint.to_i] || 0
      end

      def subset(codepoints)
        gids = codepoints.map { |cp| glyph_id_for_codepoint(cp) }.uniq.sort
        gids << 0
        options = Fontisan::Subset::Options.new(profile: 'pdf')
        builder = Fontisan::Subset::Builder.new(@fontisan_font, gids, options)
        { bytes: builder.build, gid_map: builder.mapping }
      end

      def embed(codepoints)
        sub = subset(codepoints)
        bytes = sub[:bytes]
        extract_subset_cmap(bytes)
        stream = @document.add(
          { Length: bytes.bytesize, Length1: bytes.bytesize },
          type: Pdfrb::Model::Cos::Stream
        )
        stream.stream = bytes
        font_file2 = Pdfrb::Model::Reference.new(stream.oid, stream.gen)
        descriptor = @document.add(
          { Type: :FontDescriptor, FontName: @base_font_name.to_sym,
            Flags: 32, FontBBox: font_bbox, ItalicAngle: 0,
            Ascent: ascent, Descent: descent, CapHeight: cap_height,
            StemV: 80, FontFile2: font_file2 },
          type: Pdfrb::Model::Type::FontDescriptor
        )
        cid_font = @document.add(
          { Type: :Font, Subtype: :CIDFontType2,
            BaseFont: @base_font_name.to_sym,
            CIDSystemInfo: { Registry: 'Adobe', Ordering: 'Identity', Supplement: 0 },
            CIDToGIDMap: :Identity,
            FontDescriptor: Pdfrb::Model::Reference.new(descriptor.oid, descriptor.gen),
            W: widths_array },
          type: Pdfrb::Model::Type::CIDFont
        )
        tounicode_data = build_tounicode_stream
        tounicode = @document.add(
          { Length: tounicode_data.bytesize },
          type: Pdfrb::Model::Cos::Stream
        )
        tounicode.stream = tounicode_data
        type0 = @document.add(
          { Type: :Font, Subtype: :Type0,
            BaseFont: @base_font_name.to_sym,
            Encoding: :'Identity-H',
            DescendantFonts: [Pdfrb::Model::Reference.new(cid_font.oid, cid_font.gen)],
            ToUnicode: Pdfrb::Model::Reference.new(tounicode.oid, tounicode.gen) },
          type: Pdfrb::Model::Type::FontType0
        )
        Pdfrb::Model::Reference.new(type0.oid, type0.gen)
      end

      private

      def extract_subset_cmap(bytes)
        require 'tmpdir'
        Dir.mktmpdir do |dir|
          path = File.join(dir, 'subset.ttf')
          File.binwrite(path, bytes)
          sf = Fontisan::FontLoader.load(path)
          cm = sf.table('cmap').unicode_mappings
          @subset_cp_to_gid = cm.transform_keys(&:to_i)
          @subset_gid_to_cp = invert_prefer_ascii(@subset_cp_to_gid)
        end
      rescue StandardError => e
        Arrolio::Logger.warn "subset cmap extract failed: #{e.message[0,80]}"
        @subset_cp_to_gid = @unicode_to_gid
        @subset_gid_to_cp = invert_prefer_ascii(@unicode_to_gid)
      end

      # Build GID -> codepoint map, preferring ASCII codepoints when
      # multiple codepoints share the same GID. Fonts commonly have
      # both U+0020 (SPACE) and U+00A0 (NO-BREAK SPACE) mapped to
      # the same glyph; without preference, Hash#invert would keep
      # U+00A0, breaking text extraction (pdftotext reads no-break
      # spaces as solid characters, not word separators).
      def invert_prefer_ascii(cp_to_gid)
        result = {}
        cp_to_gid.each do |cp, gid|
          existing = result[gid]
          if existing.nil?
            result[gid] = cp
          elsif cp < 0x80 && existing >= 0x80
            result[gid] = cp
          end
        end
        result
      end

      def build_tounicode_stream
        gid_to_cp = @subset_gid_to_cp || invert_prefer_ascii(@unicode_to_gid)
        lines = []
        lines << '/CIDInit /ProcSet findresource begin'
        lines << '12 dict begin'
        lines << 'begincmap'
        lines << '/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def'
        lines << '/CMapName /Adobe-Identity-UCS def'
        lines << '/CMapType 2 def'
        lines << '1 begincodespacerange'
        lines << '<0000> <FFFF>'
        lines << 'endcodespacerange'
        entries = gid_to_cp.map { |gid, cp| "<#{format('%04X', gid)}> <#{format('%04X', cp)}>" }
        entries.each_slice(100) do |slice|
          lines << "#{slice.length} beginbfchar"
          slice.each { |e| lines << e }
          lines << 'endbfchar'
        end
        lines << 'endcmap'
        lines << 'CMapName currentdict /CMap defineresource pop'
        lines << 'end'
        lines << 'end'
        lines.join("\n") + "\n"
      end

      def widths_array
        return [] unless @subset_gid_to_cp
        upem = head_units_per_em
        hmtx = @fontisan_font.table('hmtx')
        return [] unless hmtx
        groups = {}
        @subset_gid_to_cp.each do |subset_gid, cp|
          orig_gid = @unicode_to_gid[cp]
          next unless orig_gid
          metric = hmtx.metric_for(orig_gid)
          w = (metric && metric[:advance_width]) || 0
          groups[subset_gid] = (w * 1000 / upem).to_i
        end
        result = []
        sorted = groups.keys.sort
        cur_s = nil
        cur_w = []
        sorted.each do |gid|
          if cur_s.nil?
            cur_s = gid
            cur_w = [groups[gid]]
          elsif gid == cur_s + cur_w.length
            cur_w << groups[gid]
          else
            result << cur_s << cur_w
            cur_s = gid
            cur_w = [groups[gid]]
          end
        end
        result << cur_s << cur_w if cur_s
        result
      end

      def head_units_per_em
        head = @fontisan_font.table('head')
        head ? head.units_per_em : 1000
      rescue StandardError
        1000
      end

      def font_bbox
        head = @fontisan_font.table('head')
        return [0, 0, 1000, 1000] unless head
        s = 1000.0 / head.units_per_em
        [(head.x_min * s).to_i, (head.y_min * s).to_i, (head.x_max * s).to_i, (head.y_max * s).to_i]
      rescue StandardError
        [0, 0, 1000, 1000]
      end

      def ascent
        hhea = @fontisan_font.table('hhea')
        return 800 unless hhea
        (hhea.ascender * 1000 / head_units_per_em).to_i
      rescue StandardError
        800
      end

      def descent
        hhea = @fontisan_font.table('hhea')
        return -200 unless hhea
        (hhea.descender * 1000 / head_units_per_em).to_i
      rescue StandardError
        -200
      end

      def cap_height
        os2 = @fontisan_font.table('OS/2')
        return 700 unless os2
        (os2.cap_height * 1000 / head_units_per_em).to_i
      rescue StandardError
        700
      end
    end
  end
end
