# frozen_string_literal: true

require 'yaml'

module Arrolio
  class ConfigDrivenPipeline
    attr_reader :flavor_dir, :layout_spec, :adapter_rules, :flow_rules, :manifest, :strict

    def self.render(xml, io:, flavor_dir:, input_path: nil,
                    extra_image_dirs: [], logo_path: nil, metadata: {},
                    strict: false)
      new(
        flavor_dir: flavor_dir,
        input_path: input_path,
        extra_image_dirs: extra_image_dirs,
        logo_path: logo_path,
        strict: strict
      ).render(xml, io: io, metadata: metadata)
    end

    def initialize(flavor_dir:, input_path: nil, extra_image_dirs: [],
                   logo_path: nil, strict: false)
      @flavor_dir = File.expand_path(flavor_dir)
      @input_path = input_path
      @extra_image_dirs = Array(extra_image_dirs)
      @logo_path = logo_path
      @strict = strict
      @manifest = load_manifest
      @layout_spec = load_layout_spec
      @adapter_rules = load_yaml('adapter_rules.yml')
      @flow_rules = load_yaml('flow_rules.yml')
    end

    def render(xml, io:, metadata: {})
      adapter = GenericAdapter.new(rules: @adapter_rules, layout_spec: @layout_spec)
      document = adapter.convert(xml)
      document_metadata = document.metadata.merge(metadata.transform_keys(&:to_sym))
      register_fonts

      resolver = AssetResolver.from_input_path(
        @input_path,
        extra: @extra_image_dirs + [@flavor_dir]
      )
      flowables = GenericFlowBuilder.new(
        layout_spec: @layout_spec,
        rules: @flow_rules,
        asset_resolver: resolver
      ).build(document)
      engine = Engine::Paged.new(layout_spec: @layout_spec, flowables: flowables)
      pages = engine.layout
      populate_toc(pages, engine.context)

      Renderer::Pdf.new.render(
        pages,
        io: io,
        logo_path: @logo_path,
        metadata: document_metadata,
        font_paths: @layout_spec.font_paths,
        context: engine.context,
        layout_spec: @layout_spec
      )
    end

    private

    def load_manifest
      Flavor::Manifest.load(@flavor_dir)
    rescue FlavorError => e
      Arrolio::Logger.debug "no manifest loaded for #{@flavor_dir}: #{e.message}"
      nil
    end

    def load_yaml(filename)
      path = File.join(@flavor_dir, filename)
      YAML.safe_load_file(path, aliases: true) || {}
    end

    def load_layout_spec
      source = load_yaml('layout_spec.yml')
      source['font_paths'] = resolved_font_paths(source['font_paths'] || {})
      LayoutSpec::Loader.build_from_hash(source)
    end

    def resolved_font_paths(paths)
      paths.to_h do |name, path|
        resolved = path.to_s.start_with?('/') ? path : File.join(@flavor_dir, path.to_s)
        [name, resolved]
      end
    end

    def register_fonts
      FontMetrics::Registry.register_ttf_all(@layout_spec.font_paths, strict: @strict)
    end

    def populate_toc(pages, context)
      entries = context&.heading_entries
      return unless entries&.any?

      toc_rules = @flow_rules['toc'] || {}
      toc_flowables = TocBuilder.build_flowables(context, @layout_spec, rules: toc_rules)
      return if toc_flowables.empty?

      toc_page_index = pages.index { |page| page.template_role == :preface }
      return unless toc_page_index

      toc_page = pages[toc_page_index]
      region = toc_page.regions[:body]
      return unless region

      toc_rules_full = @flow_rules['toc'] || {}
      toc_top_offset = (toc_rules_full['top_offset'] || 40).to_f

      cursor_y = region.y + region.height - toc_top_offset
      new_boxes = []
      toc_flowables.each do |flowable|
        flowable.height(region.width, context)
        boxes, consumed = flowable.emit(region.x, cursor_y, region.width, context)
        new_boxes.concat(boxes)
        cursor_y -= consumed
      end

      updated_region = Output::Region.new(
        name: region.name,
        x: region.x,
        y: region.y,
        width: region.width,
        height: region.height,
        placed_boxes: region.placed_boxes + new_boxes
      )
      updated_page = Output::Page.new(
        number: toc_page.number,
        template_name: toc_page.template_name,
        template_role: toc_page.template_role,
        page_size: toc_page.page_size,
        regions: toc_page.regions.merge(body: updated_region),
        header_text: toc_page.header_text,
        footer_text: toc_page.footer_text,
        header_align: toc_page.header_align,
        footer_align: toc_page.footer_align
      )
      pages[toc_page_index] = updated_page
    end
  end
end
