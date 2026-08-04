# frozen_string_literal: true

# Arrolio::TextLayout::KnuthPlass — optimal line breaking.
module Arrolio
  module TextLayout
    module KnuthPlass
      autoload :Item, 'arrolio/text_layout/knuth_plass/item'
      autoload :Box, 'arrolio/text_layout/knuth_plass/item'
      autoload :Glue, 'arrolio/text_layout/knuth_plass/item'
      autoload :Penalty, 'arrolio/text_layout/knuth_plass/item'
      autoload :Breaker, 'arrolio/text_layout/knuth_plass/breaker'
      autoload :ItemBuilder, 'arrolio/text_layout/knuth_plass/item_builder'
    end
  end
end
