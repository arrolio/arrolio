# frozen_string_literal: true

# Arrolio::TextLayout — paragraph line-breaking. Pure + stateless.
module Arrolio
  module TextLayout
    autoload :Greedy, 'arrolio/text_layout/greedy'
    autoload :Line, 'arrolio/text_layout/line'
    autoload :BreakOpportunity, 'arrolio/text_layout/break_opportunity'
    autoload :KnuthPlass, 'arrolio/text_layout/knuth_plass'
  end
end
