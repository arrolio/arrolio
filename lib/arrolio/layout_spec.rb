# frozen_string_literal: true

# Arrolio::LayoutSpec — typed layout description, YAML-loadable.
module Arrolio
  class LayoutSpec
    autoload :PageTemplate, 'arrolio/layout_spec/page_template'
    autoload :PageTemplateSelector, 'arrolio/layout_spec/page_template_selector'
    autoload :ScaleLength, 'arrolio/layout_spec/scale_length'
    autoload :Region, 'arrolio/layout_spec/region'
    autoload :Flow, 'arrolio/layout_spec/flow'
    autoload :Loader, 'arrolio/layout_spec/loader'

    attr_reader :page_templates, :default_page_template, :styles, :flows,
                :font_paths, :header_footer_config, :cover_logo_config,
                :font_manifest_config

    def initialize(page_templates:, default_page_template:,
                   styles:, flows: {}, font_paths: {},
                   header_footer: {}, cover_logo: {}, font_manifest: {})
      @font_paths = font_paths.transform_keys(&:to_s).freeze
      @page_templates = page_templates.transform_keys(&:to_sym).freeze
      @default_page_template = default_page_template.to_sym
      @styles = styles
      @flows = flows.transform_keys(&:to_sym).freeze
      @header_footer_config = (header_footer || {}).freeze
      @cover_logo_config = (cover_logo || {}).freeze
      @font_manifest_config = (font_manifest || {}).freeze
      validate!
      freeze
    end

    def page_template(name = nil)
      key = (name || @default_page_template).to_sym
      @page_templates[key] ||
        (raise LayoutSpecError,
               "Unknown page template #{key.inspect}; have: #{@page_templates.keys.inspect}",
               spec_field: :page_template)
    end

    def resolve_style(name, fallback: nil)
      @styles.resolve(name, fallback: fallback || Style::Definition.new)
    end

    def flow(name)
      @flows[name.to_sym]
    end

    def ==(other)
      other.is_a?(self.class) &&
        page_templates == other.page_templates &&
        default_page_template == other.default_page_template &&
        styles == other.styles &&
        flows == other.flows &&
        header_footer_config == other.header_footer_config &&
        cover_logo_config == other.cover_logo_config &&
        font_manifest_config == other.font_manifest_config
    end

    alias eql? ==

    def hash
      [self.class, page_templates, default_page_template, styles, flows,
       header_footer_config, cover_logo_config, font_manifest_config].hash
    end

    private

    def validate!
      unless @page_templates.key?(@default_page_template)
        raise LayoutSpecError,
              "Default page template #{@default_page_template.inspect} is not in page_templates",
              spec_field: :default_page_template
      end

      unless @styles.is_a?(Style::Registry)
        raise LayoutSpecError,
              "styles must be a Style::Registry (got #{@styles.class})",
              spec_field: :styles
      end

      @page_templates.each do |name, tpl|
        next if tpl.is_a?(PageTemplate)

        raise LayoutSpecError,
              "page_templates[#{name.inspect}] must be a PageTemplate",
              spec_field: :page_templates
      end
    end
  end
end
