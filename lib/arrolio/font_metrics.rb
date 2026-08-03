# frozen_string_literal: true

# Arrolio::FontMetrics — glyph-width lookup.
module Arrolio
  module FontMetrics
    autoload :TrueTypeMetrics, 'arrolio/font_metrics/true_type_metrics'
    autoload :AfmMetrics, 'arrolio/font_metrics/afm_metrics'
    autoload :Registry, 'arrolio/font_metrics/registry'
  end
end
