# frozen_string_literal: true

# Arrolio::Engine — page-flow layout drivers.
module Arrolio
  module Engine
    autoload :Paged, 'arrolio/engine/paged'
    autoload :MarginCollapse, 'arrolio/engine/margin_collapse'
    autoload :CrossReferenceRegistry, 'arrolio/engine/cross_reference_registry'
  end
end
