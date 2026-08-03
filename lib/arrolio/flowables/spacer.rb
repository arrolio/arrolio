# frozen_string_literal: true

module Arrolio
  module Flowables
    class Spacer < Flowable
      attr_reader :amount

      def initialize(amount, style: Style::Definition.new)
        super(style: style)
        @amount = amount.to_f
      end

      def height(_width, _context = nil)
        @amount
      end

      def emit(_x, _y, _width, _context = nil)
        [[], @amount]
      end

      def splittable?
        true
      end

      def do_split(_width, remaining_height, _context = nil)
        if @amount <= remaining_height
          [self, nil]
        else
          [self.class.new(remaining_height), self.class.new(@amount - remaining_height)]
        end
      end
    end
  end
end
