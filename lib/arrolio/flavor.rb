# frozen_string_literal: true

module Arrolio
  # Flavor system — allows external document flavors to plug into
  # Arrolio without modifying core. Each flavor lives in its own
  # directory (XSL + 3 generated YAML files) outside the gem and is
  # rendered via Arrolio::ConfigDrivenPipeline.
  #
  # Arrolio core is flavor-agnostic: it knows about Content::Document,
  # Flowable, Engine, and Renderer — but NOT about any specific XML
  # format, XSL stylesheet, or document structure.
  #
  # Usage:
  #   # In the flavor's gem:
  #   Arrolio::Flavor::Registry.register(:my_flavor, MyFlavorPipeline)
  #
  #   # In the application:
  #   Arrolio::Flavor::Registry.for(:my_flavor).render(xml, io: f)
  module Flavor
    autoload :Registry, 'arrolio/flavor/registry'
    autoload :Manifest, 'arrolio/flavor/manifest'
  end
end
