# frozen_string_literal: true

module Arrolio
  class LayoutSpec
    # Declares a named content flow into a region. Declarative
    # only — Engine::Paged takes a flat Flowable list and a body
    # template today.
    Flow = Struct.new(:name, :region, :source, :default_style_id,
                      keyword_init: true) do
      def initialize(*)
        super
        self.name = self.name.to_sym if self.name
        freeze
      end
    end
  end
end
