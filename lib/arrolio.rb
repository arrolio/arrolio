# frozen_string_literal: true

require 'pdfrb'
require 'pdfrb/content/operators'
require 'mml'

# Arrolio -- a flavor-agnostic paged-media layout engine.
# Core knows NOTHING about specific document formats. Each flavor
# lives in its own directory (XSL + 3 generated YAML files) outside
# the gem and is rendered via Arrolio::ConfigDrivenPipeline.
module Arrolio
  autoload :VERSION, 'arrolio/version'
  autoload :Error, 'arrolio/error'
  autoload :Logger, 'arrolio/logger'
  autoload :Color, 'arrolio/color'
  autoload :TextDirection, 'arrolio/text_direction'
  autoload :WritingMode, 'arrolio/writing_mode'
  autoload :ColumnSet, 'arrolio/column_set'
  autoload :Content, 'arrolio/content'
  autoload :LayoutSpec, 'arrolio/layout_spec'
  autoload :Style, 'arrolio/style'
  autoload :Table, 'arrolio/table'
  autoload :Font, 'arrolio/font'
  autoload :FontMetrics, 'arrolio/font_metrics'
  autoload :GlyphMeasurer, 'arrolio/glyph_measurer'
  autoload :InlineRun, 'arrolio/inline_run'
  autoload :TextLayout, 'arrolio/text_layout'
  autoload :Flowable, 'arrolio/flowable'
  autoload :Flowables, 'arrolio/flowables'
  autoload :Frame, 'arrolio/frame'
  autoload :FlowContext, 'arrolio/flow_context'
  autoload :Engine, 'arrolio/engine'
  autoload :Output, 'arrolio/output'
  autoload :Renderer, 'arrolio/renderer'
  autoload :Harness, 'arrolio/harness'
  autoload :Flavor, 'arrolio/flavor'
  autoload :AssetResolver, 'arrolio/asset_resolver'
  autoload :GenericAdapter, 'arrolio/generic_adapter'
  autoload :GenericFlowBuilder, 'arrolio/generic_flow_builder'
  autoload :ConfigDrivenPipeline, 'arrolio/config_driven_pipeline'
  autoload :TocBuilder, 'arrolio/toc_builder'
  autoload :FontScanner, 'arrolio/font_scanner'
  autoload :Composer, 'arrolio/composer'
  autoload :MathML, 'arrolio/math_ml'
end
