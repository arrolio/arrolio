# frozen_string_literal: true

module Arrolio
  module Harness
    autoload :PdfDiff, 'arrolio/harness/pdf_diff'
    autoload :TextDiff, 'arrolio/harness/text_diff'
    autoload :TextExtractor, 'arrolio/harness/text_extractor'
    autoload :PixelDiff, 'arrolio/harness/pixel_diff'
  end
end
