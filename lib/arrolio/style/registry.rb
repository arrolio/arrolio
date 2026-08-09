# frozen_string_literal: true

require 'set'

module Arrolio
  module Style
    class Registry
      attr_reader :overrides

      def initialize(overrides = {})
        @overrides = {}
        @resolution_cache = {}
        overrides.each { |name, attrs| register(name, **attrs) }
        freeze
      end

      def register(name, **opts)
        @overrides[name.to_sym] = opts.transform_keys(&:to_sym)
        @resolution_cache.clear
        name.to_sym
      end

      def resolve(name, fallback: Definition.new)
        key = name.to_sym
        return fallback unless @overrides.key?(key)
        return @resolution_cache[key] if @resolution_cache.key?(key)

        chain = []
        cursor = key
        seen = Set.new
        while cursor && @overrides.key?(cursor) && seen.add?(cursor)
          chain << @overrides[cursor]
          parent = @overrides[cursor][:parent]
          cursor = parent&.to_sym
        end
        merged = chain.reverse_each.reduce({}) { |acc, h| acc.merge(h) }
        merged.delete(:parent)
        result = Definition.new(**merged)
        @resolution_cache[key] = result
        result
      end

      def names = @overrides.keys
      def key?(name) = @overrides.key?(name.to_sym)
      def [](name) = @overrides.[](name.to_sym)

      def ==(other)
        other.is_a?(self.class) && overrides == other.overrides
      end

      alias eql? ==

      def hash
        [self.class, overrides].hash
      end
    end
  end
end
