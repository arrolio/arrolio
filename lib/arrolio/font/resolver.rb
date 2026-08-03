# frozen_string_literal: true

require 'yaml'

module Arrolio
  module Font
    # Resolves font family names to absolute TTF paths using a
    # configurable chain of resolvers. Replaces the absolute-path
    # entries in `layout_spec.yml` with portable family-name
    # declarations.
    #
    # Resolution order (first hit wins):
    #   1. FontManifest (explicit mapping in the flavor)
    #   2. font_paths from layout_spec (legacy explicit paths)
    #   3. fontist manifest (if the +fontist+ gem is available at
    #      runtime; otherwise this step is skipped silently)
    #   4. PDF standard 14 fallback (e.g. "Helvetica" → built-in)
    #
    # Strict mode (strict: true) raises RenderError listing every
    # unresolved required font; lenient mode silently produces nil
    # entries and the renderer falls back to a default.
    class Resolver
      STANDARD_14 = [
        'Helvetica', 'Helvetica-Bold', 'Helvetica-Oblique', 'Helvetica-BoldOblique',
        'Times-Roman', 'Times-Bold', 'Times-Italic', 'Times-BoldItalic',
        'Courier', 'Courier-Bold', 'Courier-Oblique', 'Courier-BoldOblique',
        'Symbol', 'ZapfDingbats'
      ].freeze

      attr_reader :manifest, :font_paths, :use_fontist, :strict,
                  :resolved, :unresolved

      def initialize(manifest: nil, font_paths: {}, use_fontist: true,
                     strict: false)
        @manifest = manifest
        @font_paths = font_paths.transform_keys(&:to_s)
        @use_fontist = use_fontist
        @strict = strict
        @resolved = {}
        @unresolved = []
      end

      # Resolve a single family name. Returns the absolute path (String)
      # or nil if not found. Does NOT raise in strict mode — use
      # +#resolve_all!+ for that.
      def resolve(family_name)
        return resolved[family_name.to_s] if resolved.key?(family_name.to_s)

        path = lookup(family_name.to_s)
        resolved[family_name.to_s] = path
        track_unresolved(family_name.to_s, path)
        path
      end

      # Resolve every family declared by the manifest or font_paths.
      # In strict mode, raises RenderError with the full unresolved
      # list. Returns a Hash { family => path } otherwise.
      def resolve_all!
        families_to_resolve.each { |family| resolve(family) }
        return resolved unless strict && unresolved.any?

        raise ::Arrolio::RenderError.new(
          "strict mode: unresolved required fonts: #{unresolved.join(', ')}",
          missing_fonts: unresolved.map { |name| [name, nil] }
        )
      end

      def self.from_layout_spec(layout_spec, strict: false)
        new(
          manifest: layout_font_manifest(layout_spec),
          font_paths: layout_spec.font_paths,
          use_fontist: true,
          strict: strict
        )
      end

      def self.standard_14?(family_name)
        STANDARD_14.include?(family_name.to_s)
      end

      private

      def lookup(family)
        return manifest_path(family) if @manifest&.path_for(family)
        return @font_paths[family] if @font_paths.key?(family) && File.exist?(@font_paths[family].to_s)

        fontist_path = fontist_lookup(family)
        return fontist_path if fontist_path

        STANDARD_14.include?(family) ? family : nil
      end

      def manifest_path(family)
        path = @manifest.path_for(family)
        path && File.exist?(path) ? path : nil
      end

      def fontist_lookup(family)
        return nil unless @use_fontist
        return nil unless fontist_available?

        fontist_manifest = ::Fontist.manifest
        fontist_manifest.install(family) unless fontist_manifest.any? { |e| e.name == family }
        ::Fontist::Font.find(family).paths.first
      rescue StandardError
        nil
      end

      def fontist_available?
        Object.const_defined?(:Fontist)
      end

      def families_to_resolve
        required = @manifest ? @manifest.required_families : []
        (required + @font_paths.keys).uniq
      end

      def track_unresolved(family, path)
        return if path

        is_standard = self.class.standard_14?(family)
        @unresolved << family unless is_standard
      end

      def self.layout_font_manifest(layout_spec)
        return nil unless layout_spec.is_a?(::Arrolio::LayoutSpec)

        config = layout_spec.font_manifest_config
        return nil unless config && config['families']

        FontManifest.new(config['families'], config.fetch('fallback', []))
      end
      private_class_method :layout_font_manifest
    end

    # Internal lightweight view over a `font_manifest:` block in
    # layout_spec.yml. Maps family names to variant paths and exposes
    # the required-family list.
    class FontManifest
      attr_reader :families, :fallback

      def initialize(families, fallback = [])
        @families = families.transform_keys(&:to_s)
        @fallback = Array(fallback)
        freeze
      end

      def path_for(family)
        entry = @families[family.to_s]
        return nil unless entry

        path = entry['regular'] || entry[:regular]
        path&.to_s
      end

      def required_families
        @families.keys
      end
    end
  end
end
