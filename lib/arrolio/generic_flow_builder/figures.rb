# frozen_string_literal: true

module Arrolio
  class GenericFlowBuilder
    # Extracted emission seam: one module per content family, the
    # same pattern as GenericAdapter's decomposition. The class
    # keeps build(), dispatch, and shared helpers.
    module Figures
    INLINE_SVG_PREFIX = 'inline-svg:'
    # Figures are atomic: image + caption render as ONE flowable
    # so the caption can never be orphaned onto the next page.
    # Caption gap is flavor geometry (ref: image bottom to caption
    # ~28pt; figure blocks separated by ~24pt).
    def figure_group_flowable(group, out)
      figure_config = @rules['figure'] || {}
      caption_gap = figure_config.fetch('caption_gap', 0.0).to_f
      block_gap = figure_config.fetch('block_gap', 0.0).to_f

      image = image_flowable(group.image) if group.image
      if group.caption
        caption_style = resolve(:figure_caption).with(margin_top: caption_gap)
        runs = group.caption.inline_runs.map do |run|
          InlineRun.new(run.text, style: caption_style)
        end
        caption = Flowables::TextFlowable.new(runs, style: caption_style)
      end
      return out << caption if image.nil?

      image = with_block_gap(image, block_gap)
      out << if caption
               Flowables::FigureFlowable.new(image, caption)
             else
               image
             end
    end

    def with_block_gap(flowable, gap)
      return flowable if gap.zero?

      style = flowable.style.with(margin_top: flowable.style.margin_top + gap)
      flowable.class.new(flowable.src,
                         natural_width: flowable.natural_width,
                         natural_height: flowable.natural_height,
                         display_width: flowable.display_width,
                         alt: flowable.alt,
                         style: style)
    end

    def image_flowable(image)
      source = resolve_image_source(image)
      image_rules = @rules['image'] || {}
      default_width = (image_rules['default_natural_width'] || 400).to_f
      default_height = (image_rules['default_natural_height'] || 300).to_f
      max_width = (image_rules['max_display_width'] || 106).to_f
      natural_width = image.width || svg_dimension(source, 'width') || default_width
      natural_height = image.height || svg_dimension(source, 'height') || default_height
      display_width = [image.width || natural_width, max_width].min
      Flowables::ImageFlowable.new(
        source,
        natural_width: natural_width,
        natural_height: natural_height,
        display_width: display_width,
        alt: image.alt,
        style: resolve(image.style_id)
      )
    end

    def resolve_image_source(image)
      return asset_resolver.resolve(image.src) unless image.src.is_a?(String)
      return write_inline_svg(image.src) if image.src.start_with?(INLINE_SVG_PREFIX)

      asset_resolver.resolve(image.src)
    end

    def write_inline_svg(prefixed)
      svg_xml = prefixed[INLINE_SVG_PREFIX.length..]
      path = File.join(Dir.mktmpdir('arrolio-svg'), 'figure.svg')
      File.write(path, svg_xml)
      path
    end

    def svg_dimension(source, name)
      return nil unless source && File.exist?(source) && source.match?(/\.svg\z/i)

      value = File.read(source)[/(?:#{name})=["']([\d.]+)/, 1]
      value && (value.to_f * SVG_PX_TO_PT)
    end
    end
  end
end
