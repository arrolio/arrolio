# frozen_string_literal: true

require 'stringio'
require 'digest/md5'
require 'tmpdir'

module Arrolio
  module Renderer
    # Walks Output::Page[] and emits PDF bytes via Pdfrb. Supports
    # font embedding: pass +font_paths:+ as a Hash mapping the
    # Style#font_name string to a TTF path, and the renderer will
    # subset + embed each font for the codepoints actually used
    # in the document.
    class Pdf
      MM_TO_PT = 2.83464567

      attr_reader :document, :fonts

      def initialize
        @document = Pdfrb::Document.new
        @fonts = FontRegistry.new(@document)
        @images = {}
        @font_paths = {}
        @font_embedders = {}
        @font_encoders = {}
        @font_refs = {}
        @link_annotator = LinkAnnotator.new(@document)
      end

      def render(pages, io:, logo_path: nil, metadata: {},
                 font_paths: {}, context: nil, layout_spec: nil)
        @font_paths = font_paths.transform_keys(&:to_s)
        @layout_spec = layout_spec
        apply_metadata(metadata)
        attach_xmp_metadata(metadata)
        @logo_ref = register_logo(logo_path)
        prepare_embedded_fonts(pages)
        pages.each { |page| render_page(page) }
        build_outline(context, pages) if context
        @document.write(io.is_a?(String) ? io : nil,
                        io: io.is_a?(String) ? nil : io)
      end

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

      def register_logo(path)
        return nil unless path

        @document.images.add(path)
      rescue StandardError => e
        Arrolio::Logger.warn "logo load failed: #{e.class}: #{e.message[0, 80]}"
        nil
      end

      def register_image(path)
        return @images[path] if @images.key?(path)

        resolved = resolve_image_for_pdfrb(path)
        return nil unless resolved

        @images[path] = @document.images.add(resolved)
      rescue StandardError => e
        Arrolio::Logger.warn "register_image failed for #{path}: #{e.class}: #{e.message[0, 80]}"
        nil
      end

      # Pdfrb supports JPEG, PNG, and PDF — not SVG. If +path+ is an
      # SVG file, rasterize it to PNG via rsvg-convert and cache the
      # result. Returns the path to a pdfrb-compatible image file.
      def resolve_image_for_pdfrb(path)
        return path unless path.to_s.end_with?('.svg', '.SVG')
        return path unless File.exist?(path)

        png_path = svg_to_png_cache_path(path)
        return png_path if File.exist?(png_path)

        rasterize_svg(path, png_path)
        File.exist?(png_path) ? png_path : path
      end

      def svg_to_png_cache_path(svg_path)
        digest = Digest::MD5.file(svg_path).hexdigest
        File.join(Dir.tmpdir, 'arrolio-svg-' + digest + '.png')
      end

      def rasterize_svg(svg_path, png_path)
        require 'open3'
        result = Open3.capture3('rsvg-convert', '-d', '96', '-p', '96',
                                '-o', png_path, svg_path)
        return if result[2].success?

        Arrolio::Logger.warn "rsvg-convert failed: #{result[1]}"
      rescue StandardError => e
        Arrolio::Logger.warn "rasterize_svg failed: #{e.class}: #{e.message[0, 80]}"
      end

      def header_footer_style
        return @header_footer_style if @header_footer_style

        config = @layout_spec&.header_footer_config || {}
        @header_footer_style = {
          margin_top: (config['margin_top'] || 26.5) * MM_TO_PT,
          margin_bottom: (config['margin_bottom'] || 26.5) * MM_TO_PT,
          margin_lr: (config['margin_lr'] || 25.5) * MM_TO_PT,
          header_offset: (config['header_offset'] || 4) * MM_TO_PT,
          footer_offset: (config['footer_offset'] || 4) * MM_TO_PT,
          font_name: config['font_name'] || 'Helvetica',
          font_size: config['font_size'] || 9.0,
          rule_width: config['rule_width'] || 0.5
        }.freeze
      end

      def cover_logo_style
        return @cover_logo_style if @cover_logo_style

        config = @layout_spec&.cover_logo_config || {}
        width_mm = config['width_mm'] || 35.0
        ratio = config['aspect_ratio'] || (1459.0 / 1667.0)
        margin_mm = config['margin_mm'] || 25.5
        @cover_logo_style = {
          width: width_mm * MM_TO_PT,
          height: width_mm * ratio * MM_TO_PT,
          margin: margin_mm * MM_TO_PT
        }.freeze
      end

      private

      # Pre-scan all pages, collect codepoints per font family,
      # then call Font::Embedder for each font_path.
      def prepare_embedded_fonts(pages)
        return if @font_paths.empty?

        codepoints = Hash.new { |h, k| h[k] = [] }
        pages.each { |page| collect_codepoints(page, codepoints) }
        Arrolio::Logger.debug "collected codepoints for fonts: #{codepoints.keys.inspect}"
        @font_paths.each do |font_name, path|
          exists = File.exist?(path)
          has_cp = codepoints.key?(font_name)
          cp_count = codepoints[font_name]&.length || 0
          Arrolio::Logger.debug "font #{font_name}: exists=#{exists} cp=#{cp_count}"
          next unless exists
          next unless has_cp

          cps = codepoints[font_name].uniq
          embedder = Font::Embedder.new(@document, path,
                                        base_font_name: font_name)
          ref = embedder.embed(cps)
          attach_to_resources(font_name, ref)
          @font_embedders[font_name] = embedder
          @font_encoders[font_name] = Font::TextEncoder.new(embedder)
          @font_refs[font_name] = ref
        rescue StandardError => e
          Arrolio::Logger.warn "embed failed for #{font_name}: #{e.class}: #{e.message[0,100]}"
          Arrolio::Logger.debug e.backtrace.first(5).join("\n")
        end
      end

      def attach_to_resources(font_name, ref)
        catalog = @document.catalog
        res = catalog.value[:Resources]
        Arrolio::Logger.debug "attach_to_resources: Resources=#{res.class}"
        unless res.is_a?(Hash) && res[:Font].is_a?(Hash)
          catalog.value[:Resources] = { Font: {} }
        end
        font_hash = catalog.value[:Resources][:Font]
        key = (format('EF%d', (font_hash.length + 1))).to_sym
        font_hash[key] = ref
        @embedded_resource_keys ||= {}
        @embedded_resource_keys[font_name] = key
      end

      def collect_codepoints(page, by_font)
        (page.static_regions.values + page.regions.values).each do |region|
          region.placed_boxes.each do |box|
            next unless box.kind == :text
            next unless box.data.is_a?(Hash) && box.data[:lines]

            box.data[:lines].each do |line|
              next unless line.is_a?(TextLayout::Line)
              line.placed_runs.each do |pr|
                next unless pr.run.is_a?(InlineRun)
                # Collect under the RUN'S font name, not the
                # paragraph's. Italic/bold runs have different
                # font_names and need their own subsets.
                run_font = pr.run.style.font_name
                next unless @font_paths.key?(run_font)
                pr.run.text.each_codepoint { |cp| by_font[run_font] << cp }
              end
            end
          end
        end
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

      def render_page(output_page)
        pdfrb_page = @document.pages.add(media_box: [0, 0,
                                                     output_page.width,
                                                     output_page.height])
        catalog = @document.catalog
        catalog.value[:Resources] ||= { Font: {} }
        pdfrb_page.value[:Resources] = catalog.value[:Resources]
        canvas = pdfrb_page.canvas
        render_cover_logo(canvas, output_page) if output_page.template_role == :cover && @logo_ref
        render_header_footer(canvas, output_page) unless output_page.template_role == :cover
        (output_page.static_regions.values + output_page.regions.values).each do |region|
          region.placed_boxes.each { |box| render_box(canvas, box) }
        end
        @link_annotator.flush(pdfrb_page)
      end

      def render_cover_logo(canvas, page)
        logo_style = cover_logo_style
        w = logo_style[:width]
        h = logo_style[:height]
        margin = logo_style[:margin]
        x = page.width - margin - w
        y = page.height - margin - h
        invoke = invoke_xobject_op
        return unless invoke

        canvas.save_graphics_state do
          canvas.concat(w, 0, 0, h, x, y)
          canvas.emit_op(invoke, @logo_ref)
        end
      rescue StandardError => e
        Arrolio::Logger.warn "logo render failed: #{e.class}: #{e.message[0, 80]}"
      end

      def invoke_xobject_op
        return Pdfrb::Content::Operator::InvokeXObject if defined?(Pdfrb::Content::Operator::InvokeXObject)

        @invoke_xobject_class ||= Class.new(Pdfrb::Content::Operator::Base) do
          def self.name = 'Do'
        end
      end

      def render_header_footer(canvas, page)
        hf_style = header_footer_style
        margin_top = hf_style[:margin_top]
        margin_bottom = hf_style[:margin_bottom]
        margin_lr = hf_style[:margin_lr]
        header_offset = hf_style[:header_offset]
        footer_offset = hf_style[:footer_offset]
        page_w = page.width
        page_h = page.height
        before_y = page_h - margin_top + header_offset
        after_y = margin_bottom - footer_offset

        if page.header_text
          emit_header_or_footer(canvas, page.header_text, before_y,
                                page.header_align, page_w, margin_lr, true, hf_style)
        end
        return unless page.footer_text

        emit_header_or_footer(canvas, page.footer_text, after_y,
                              page.footer_align, page_w, margin_lr, false, hf_style)
      end

      def emit_header_or_footer(canvas, text, y, align, page_w, margin_lr, top, hf_style)
        font_name = hf_style[:font_name]
        size = hf_style[:font_size]
        measurer = GlyphMeasurer.new(font_name: font_name)
        tw = measurer.width_of_string(text, font_size: size)
        x = case align
            when :center then (page_w - tw) / 2.0
            when :right then page_w - margin_lr - tw
            else margin_lr
            end
        ref = embedded_or_standard(font_name)
        payload = encoded_or_text(font_name, text)
        canvas.text(payload, at: [x, y], font: ref, size: size)
        canvas.line_width = hf_style[:rule_width]
        canvas.stroke_color(0.0)
        rule_y = top ? y - 2 : y + size + 2
        canvas.line(margin_lr, rule_y, page_w - margin_lr, rule_y)
        canvas.stroke
      end

      def render_box(canvas, box)
        case box.kind
        when :text then render_text(canvas, box)
        when :rect then render_rect(canvas, box)
        when :line then render_line(canvas, box)
        when :image then render_image(canvas, box)
        end
      end

      def render_text(canvas, box)
        lines = box.data[:lines]
        line_height = box.data[:line_height]
        style = box.data[:style]
        measurer = GlyphMeasurer.new(font_name: style.font_name)
        ascender = measurer.ascender(font_size: style.font_size)
        x_origin = box.x
        y_top = box.y + box.height

        lines.each_with_index do |line, idx|
          baseline_y = y_top - (idx * line_height) - ascender
          line_x = x_origin + line.x_offset
          render_line_runs(canvas, line, line_x, baseline_y, style)
        end
      end

      def render_line_runs(canvas, line, line_x, baseline_y, _paragraph_style)
        justify = line.justified? ? line.justify_stretch : 0.0
        extra_offset = 0.0
        line.placed_runs.each do |pr|
          run = pr.run
          x = line_x + pr.x_offset + extra_offset
          font_name = run.style.font_name
          ref = embedded_or_standard(font_name)
          payload = encoded_or_text(font_name, run.text)
          y, size = baseline_position_for(run, baseline_y)
          opts = { at: [x, y], font: ref, size: size }
          if run.style.character_spacing && !run.style.character_spacing.zero?
            opts[:char_spacing] = run.style.character_spacing
          end
          if run.style.word_spacing && !run.style.word_spacing.zero?
            opts[:word_spacing] = run.style.word_spacing
          end
          record_link_if_needed(run, x, y, opts[:size])
          canvas.text(payload, **opts)
          extra_offset += (run.text.count(' ') * justify) if justify.positive?
        end
      end

      # Returns [y, font_size] for a run, applying baseline shift and
      # font size scaling for subscript/superscript runs.
      # Subscript: shift down 0.2em, scale 0.7x.
      # Superscript: shift up 0.4em, scale 0.7x.
      def baseline_position_for(run, baseline_y)
        base_size = run.style.font_size
        return [baseline_y, base_size] unless run.is_a?(InlineRun)

        case run.baseline_shift
        when Content::InlineRun::BASELINE_SUB
          [baseline_y - (base_size * 0.2), base_size * run.font_size_scale]
        when Content::InlineRun::BASELINE_SUP
          [baseline_y + (base_size * 0.4), base_size * run.font_size_scale]
        else
          [baseline_y, base_size]
        end
      end

      # Returns the PDF resource ref for a font name. Embedded
      # fonts use the Type0 ref registered during prepare_embedded_fonts;
      # everything else falls back to the standard 14 path via
      # FontRegistry (Helvetica, Times-Roman, etc.).
      def embedded_or_standard(font_name)
        key = @embedded_resource_keys&.[](font_name)
        return key if key

        @fonts.resolve(font_name)
      end

      # Returns the text payload to emit: encoded 2-byte GID
      # sequence for embedded fonts, or the raw Unicode string for
      # standard 14 fonts (whose /Encoding is implicit WinAnsi).
      def encoded_or_text(font_name, text)
        encoder = @font_encoders[font_name]
        return text unless encoder

        encoder.encode(text)
      end

      def render_rect(canvas, box)
        stroke = box.data[:stroke_width]
        stroke_color = box.data[:stroke_color]
        fill_color = box.data[:fill_color]
        canvas.rectangle(box.x, box.y, box.width, box.height)
        if fill_color
          canvas.fill_color(parse_color(fill_color))
          canvas.fill
        end
        return unless stroke&.to_f&.positive?

        canvas.line_width = stroke.to_f
        canvas.stroke_color(parse_color(stroke_color)) if stroke_color
        canvas.stroke
      end

      def render_line(canvas, box)
        d = box.data
        canvas.line(d[:x1], d[:y1], d[:x2], d[:y2])
        canvas.line_width = d[:stroke_width].to_f
        canvas.stroke_color(parse_color(d[:stroke_color])) if d[:stroke_color]
        canvas.stroke
      end

      def render_image(canvas, box)
        ref = resolve_image_ref(box.data[:image_ref])
        return unless ref

        invoke = invoke_xobject_op
        return unless invoke

        canvas.save_graphics_state do
          canvas.concat(box.width, 0, 0, box.height, box.x, box.y)
          canvas.emit_op(invoke, ref)
        end
      end

      def resolve_image_ref(image_ref)
        return image_ref if image_ref.is_a?(Symbol)

        register_image(image_ref.to_s)
      end

      def record_link_if_needed(run, x, baseline_y, font_size)
        return unless run.is_a?(InlineRun) && run.hyperlink?

        approx_width = run.text.length * font_size * 0.5
        @link_annotator.record_link(
          x: x, y: baseline_y - 2,
          width: approx_width, height: font_size + 2,
          uri: run.href
        )
      end

      def parse_color(spec)
        return spec if spec.is_a?(Array) || spec.is_a?(Numeric)
        return 0.0 if spec.nil? || spec.to_s.empty?

        color = Color.parse(spec)
        return 0.0 unless color

        color.grayscale? ? color.to_grayscale_float : color.to_render
      end
    end
  end
end
