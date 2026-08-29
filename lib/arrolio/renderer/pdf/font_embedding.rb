# frozen_string_literal: true

module Arrolio
  module Renderer
    class Pdf
      # Extracted concern: Pdfrb coupling points kept out of the
      # emission path.
      module FontEmbedding
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
      end
    end
  end
end
