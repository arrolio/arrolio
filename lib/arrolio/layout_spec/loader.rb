# frozen_string_literal: true

require 'yaml'

module Arrolio
  class LayoutSpec
    # Loads a LayoutSpec from YAML. Lengths accept mm/cm/in/pt/px.
    module Loader
      MM_TO_PT = 2.83464567
      CM_TO_PT = 28.3464567
      IN_TO_PT = 72.0
      PT_TO_PT = 1.0
      PX_TO_PT = 0.75

      module_function

      def load(source)
        build_from_hash(read_yaml(source))
      end

      def read_yaml(source)
        case source
        when Hash then source
        when String
          if File.exist?(source)
            result = YAML.safe_load_file(source, aliases: true)
            result.is_a?(Hash) ? result : {}
          else
            result = YAML.safe_load(source, aliases: true)
            result.is_a?(Hash) ? result : {}
          end
        when IO, StringIO
          result = YAML.safe_load(source.read, aliases: true)
          result.is_a?(Hash) ? result : {}
        else
          raise ArgumentError, "Loader needs Hash/String/IO; got #{source.class}"
        end
      end

      def build_from_hash(hash)
        templates = build_templates(hash.fetch('page_templates', {}))
        default = hash.fetch('default_page_template') do
          templates.keys.first or
            raise LayoutSpecError, 'no page templates in layout spec', spec_field: :page_templates
        end
        styles = Style::Registry.new(hash.fetch('styles', {}))
        flows = hash.fetch('flows', {}).transform_values do |f|
          f = { 'region' => f } unless f.is_a?(Hash)
          Flow.new(
            name: f['name'],
            region: f['region']&.to_sym,
            source: f['source'],
            default_style_id: f['default_style_id']&.to_sym
          )
        end
        LayoutSpec.new(
          page_templates: templates,
          default_page_template: default,
          styles: styles,
          flows: flows,
          font_paths: hash.fetch('font_paths', {}),
          header_footer: hash.fetch('header_footer', {}),
          cover_logo: hash.fetch('cover_logo', {}),
          font_manifest: hash.fetch('font_manifest', {})
        )
      end

      def build_templates(hash)
        hash.to_h do |name, attrs|
          attrs = {} unless attrs.is_a?(Hash)
          [name, build_template(name, attrs)]
        end
      end

      def build_template(name, attrs)
        PageTemplate.new(
          name: name,
          page_size: attrs['page_size'] || PageTemplate::LETTER,
          margins: build_margins(attrs),
          region_extents: build_region_extents(attrs.fetch('region_extents', {}))
        )
      end

      def build_margins(attrs)
        margins = attrs['margins']
        return PageTemplate::LETTER.first if margins.nil?

        case margins
        when Numeric, String then { all: parse_length(margins) }
        when Hash
          margins.to_h { |k, v| [k.to_sym, parse_length(v)] }
        else
          raise LayoutSpecError, 'margins must be number/string/hash', spec_field: :margins
        end
      end

      def build_region_extents(hash)
        hash.to_h { |k, v| [k.to_sym, parse_length(v)] }
      end

      def parse_length(value)
        return value.to_f if value.is_a?(Numeric)

        case value.to_s
        when /\A([\d.]+)mm\z/ then Regexp.last_match(1).to_f * MM_TO_PT
        when /\A([\d.]+)cm\z/ then Regexp.last_match(1).to_f * CM_TO_PT
        when /\A([\d.]+)in\z/ then Regexp.last_match(1).to_f * IN_TO_PT
        when /\A([\d.]+)px\z/ then Regexp.last_match(1).to_f * PX_TO_PT
        when /\A([\d.]+)pt\z/ then Regexp.last_match(1).to_f * PT_TO_PT
        when /\A[\d.]+\z/ then value.to_f
        else
          raise LayoutSpecError, "cannot parse length #{value.inspect}", spec_field: :length
        end
      end
    end
  end
end
