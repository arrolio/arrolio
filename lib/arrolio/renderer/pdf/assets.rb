# frozen_string_literal: true

module Arrolio
  module Renderer
    class Pdf
      # Extracted concern: Pdfrb coupling points kept out of the
      # emission path.
      module Assets
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
      end
    end
  end
end
