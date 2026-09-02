# frozen_string_literal: true

module Arrolio
  # Table layout algorithms. Currently:
  # - AutoLayout — content-based column width computation.
  module Table
    autoload :AutoLayout, 'arrolio/table/auto_layout'
    autoload :Grid, 'arrolio/table/grid'
    autoload :SplitPolicy, 'arrolio/table/split_policy'
  end
end
