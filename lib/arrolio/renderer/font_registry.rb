# frozen_string_literal: true

module Arrolio
  module Renderer
    # Maps font family names to Pdfrb resource Symbols.
    class FontRegistry
      attr_reader :document

      def initialize(document)
        @document = document
        @refs = {}
      end

      def resolve(font_name)
        key = font_name.to_s
        return @refs[key] if @refs.key?(key)

        @refs[key] = begin
          ref = @document.fonts.add(key)
          ref || key.to_sym
        rescue StandardError
          fallback = @refs['Helvetica'] ||= @document.fonts.add('Helvetica')
          fallback
        end
      end

      def known_fonts
        @refs.keys
      end
    end
  end
end
