# frozen_string_literal: true

module Arrolio
  module Font
    # Declarative font configuration. Maps family names to variant
    # file paths (regular, bold, italic, bold_italic) and provides
    # fallback chain resolution. Replaces the flat +font_paths+
    # hash on LayoutSpec with a richer structure.
    #
    # Manifest format (YAML):
    #   families:
    #     "Body Font":
    #       regular: /path/to/times.ttf
    #       bold: /path/to/timesbd.ttf
    #       italic: /path/to/timesi.ttf
    #       bold_italic: /path/to/timesbi.ttf
    #   fallback: ["Fallback1", "Fallback2"]
    class Manifest
      attr_reader :families, :fallback_chain

      # +families:+ Hash mapping family name (String) to a Hash of
      #   variant → file path. Variants: :regular, :bold, :italic,
      #   :bold_italic.
      # +fallback_chain:+ Array of family names tried in order when
      #   the primary family doesn't have a needed variant.
      def initialize(families:, fallback_chain: [])
        @families = normalize_families(families)
        @fallback_chain = Array(fallback_chain).map(&:to_s)
        freeze
      end

      # Resolves a font name + weight + style to a file path.
      # Tries the primary family first, then the fallback chain.
      # Returns nil if no path is found.
      def resolve(font_name, weight: :regular, style: :regular)
        variant = variant_key(weight, style)
        path = lookup(@families[font_name.to_s], variant)
        return path if path

        @fallback_chain.each do |family|
          path = lookup(@families[family], variant)
          return path if path
        end
        nil
      end

      # Returns all (family, variant, path) triples as a flat hash
      # suitable for the existing +font_paths+ API.
      def to_flat_paths
        result = {}
        @families.each do |family, variants|
          variants.each do |variant, path|
            key = variant_name(family, variant)
            result[key] = path if path && File.exist?(path)
          end
        end
        result
      end

      # Factory: builds a Manifest from a YAML/Hash representation.
      def self.from_hash(hash)
        new(
          families: hash.fetch('families', hash.fetch(:families, {})),
          fallback_chain: hash.fetch('fallback', hash.fetch(:fallback_chain, []))
        )
      end

      def ==(other)
        other.is_a?(self.class) &&
          families == other.families &&
          fallback_chain == other.fallback_chain
      end
      alias eql? ==

      def hash
        [self.class, families, fallback_chain].hash
      end

      private

      def normalize_families(raw)
        raw.to_h.transform_keys(&:to_s).transform_values do |variants|
          variants.to_h.transform_keys(&:to_sym)
        end
      end

      def variant_key(weight, style)
        is_bold = weight.to_s.downcase == 'bold'
        is_italic = style.to_s.downcase == 'italic'
        if is_bold && is_italic then :bold_italic
        elsif is_bold then :bold
        elsif is_italic then :italic
        else :regular
        end
      end

      def lookup(family_variants, variant)
        return nil unless family_variants

        family_variants[variant] || family_variants[:regular]
      end

      def variant_name(family, variant)
        case variant
        when :regular then family
        when :bold then "#{family} Bold"
        when :italic then "#{family} Italic"
        when :bold_italic then "#{family} BoldItalic"
        else family
        end
      end
    end
  end
end
