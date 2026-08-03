# frozen_string_literal: true

module Arrolio
  module Flowables
    # Forces a page break AND switches the active page sequence:
    # role + header/footer templates apply to subsequent pages
    # until the next PageSequenceStart.
    class PageSequenceStart < Flowable
      attr_reader :role, :header_template, :footer_template,
                  :header_align, :footer_align, :initial_page_number

      def initialize(role:, header_template: nil, footer_template: nil,
                     header_align: :right, footer_align: :center,
                     initial_page_number: nil)
        @role = role.to_sym
        @header_template = header_template
        @footer_template = footer_template
        @header_align = header_align.to_sym
        @footer_align = footer_align.to_sym
        @initial_page_number = initial_page_number
      end

      def height(_width, _context = nil) = 0.0

      def emit(_x, _y, _width, _context = nil) = [[], 0.0]
    end
  end
end
