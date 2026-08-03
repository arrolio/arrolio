# frozen_string_literal: true

module Arrolio
  module Flavor
    # Flavor registry. Flavors register their pipeline class at
    # load time; applications look up flavors by name. This enables
    # multiple flavors to coexist without
    # the core engine knowing about any of them.
    #
    # A flavor's pipeline class must respond to:
    #   .render(xml, io:, **opts) — render XML to PDF bytes
    #
    # Example:
    #   Arrolio::Flavor::Registry.register(:my_flavor, Arrolio::Oiml::Pipeline)
    #   Arrolio::Flavor::Registry.for(:my_flavor).render(xml, io: io)
    class Registry
      @flavors = {}

      class << self
        attr_reader :flavors

        # Register a flavor by name. +pipeline_class+ must respond
        # to +.render(xml, io:, **opts)+.
        def register(name, pipeline_class)
          @flavors[name.to_sym] = pipeline_class
        end

        # Look up a registered flavor. Returns the pipeline class
        # or raises if not found.
        def for(name)
          key = name.to_sym
          @flavors[key] ||
            raise(ArgumentError,
                  "Unknown flavor #{name.inspect}; registered: #{@flavors.keys.inspect}")
        end

        # All registered flavor names.
        def names
          @flavors.keys
        end

        # Is a flavor registered?
        def registered?(name)
          @flavors.key?(name.to_sym)
        end

        # Clear all registrations — used in specs.
        def reset!
          @flavors.clear
        end
      end
    end
  end
end
