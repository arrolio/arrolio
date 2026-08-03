# frozen_string_literal: true

require 'stringio'

# Arrolio::Renderer — walks Output::Page[] and emits bytes.
module Arrolio
  module Renderer
    autoload :Pdf, 'arrolio/renderer/pdf'
    autoload :FontRegistry, 'arrolio/renderer/font_registry'
    autoload :OutlineBuilder, 'arrolio/renderer/outline_builder'
    autoload :XmpBuilder, 'arrolio/renderer/xmp_builder'
    autoload :AccessibilityTagger, 'arrolio/renderer/accessibility_tagger'
    autoload :LinkAnnotator, 'arrolio/renderer/link_annotator'
    autoload :StructureTreeBuilder, 'arrolio/renderer/structure_tree_builder'
    autoload :SignatureConfig, 'arrolio/renderer/signature_config'
  end
end
