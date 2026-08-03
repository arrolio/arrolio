# frozen_string_literal: true

# Arrolio::Output — the medium-neutral laid-out page tree.
module Arrolio
  module Output
    autoload :Page, 'arrolio/output/page'
    autoload :Region, 'arrolio/output/region'
    autoload :PlacedBox, 'arrolio/output/placed_box'
  end
end
