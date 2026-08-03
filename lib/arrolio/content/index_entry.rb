# frozen_string_literal: true

module Arrolio
  module Content
    # A single index entry — a term and the page(s) where it appears.
    # Part of a back-of-book index section. The adapter extracts
    # these from <index>/<primary> elements; the FlowBuilder renders
    # them alphabetically with page numbers.
    class IndexEntry
      attr_reader :term, :page_numbers, :see_also, :style_id

      def initialize(term:, page_numbers:, see_also: [], style_id: :index_entry)
        @term = term.to_s
        @page_numbers = Array(page_numbers).map(&:to_i).sort.uniq.freeze
        @see_also = Array(see_also).map(&:to_s).freeze
        @style_id = style_id.to_sym
        freeze
      end

      def add_page(number)
        return self if @page_numbers.include?(number.to_i)

        self.class.new(
          term: @term,
          page_numbers: @page_numbers + [number.to_i],
          see_also: @see_also,
          style_id: @style_id
        )
      end

      def first_letter
        @term[0]&.upcase || ''
      end

      def page_numbers_str
        @page_numbers.join(', ')
      end

      def ==(other)
        other.is_a?(self.class) &&
          term == other.term &&
          page_numbers == other.page_numbers &&
          see_also == other.see_also
      end
      alias eql? ==

      def hash
        [self.class, term, page_numbers, see_also].hash
      end
    end
  end
end
