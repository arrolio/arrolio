# frozen_string_literal: true

module Arrolio
  class LayoutSpec
    # Selects the appropriate page template based on page parity
    # (odd/even) and the configured template set. Supports three
    # modes:
    #   - Single template (current behavior): always returns the
    #     same template for every page.
    #   - Odd/even templates: returns different templates for odd
    #     vs even pages, typically mirroring the inner/outer margins
    #     for double-sided printing.
    #   - Custom mapping: caller provides a proc or hash mapping
    #     page numbers to template names.
    class PageTemplateSelector
      attr_reader :default_template, :odd_template, :even_template

      # +default_template:+ template name used when no odd/even
      #   templates are configured.
      # +odd_template:+ template name for odd pages (1, 3, 5, ...).
      # +even_template:+ template name for even pages (2, 4, 6, ...).
      def initialize(default_template:, odd_template: nil, even_template: nil)
        @default_template = default_template.to_sym
        @odd_template = odd_template&.to_sym
        @even_template = even_template&.to_sym
        freeze
      end

      # Returns the template name for the given page number.
      def name_for(page_number)
        return @default_template unless @odd_template || @even_template

        if page_number.odd?
  (@odd_template || @default_template)
else
  (@even_template || @default_template)
end
      end

      # Does this selector use different templates for odd/even?
      def alternating?
        !(@odd_template.nil? && @even_template.nil?)
      end

      def ==(other)
        other.is_a?(self.class) &&
          default_template == other.default_template &&
          odd_template == other.odd_template &&
          even_template == other.even_template
      end
      alias eql? ==

      def hash
        [self.class, default_template, odd_template, even_template].hash
      end
    end
  end
end
