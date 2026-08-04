# frozen_string_literal: true

module Arrolio
  module Output
    class Page
      attr_reader :number, :template_name, :template_role, :page_size,
                  :regions, :static_regions, :header_text, :footer_text,
                  :header_align, :footer_align, :footnotes

      def initialize(number:, template_name:, page_size:,
                     regions:, static_regions: {}, template_role: :body,
                     header_text: nil, footer_text: nil,
                     header_align: :right, footer_align: :center,
                     footnotes: [])
        @number = number.to_i
        @template_name = template_name.to_sym
        @template_role = template_role.to_sym
        @page_size = [page_size[0].to_f, page_size[1].to_f].freeze
        @regions = regions.transform_keys(&:to_sym).freeze
        @static_regions = static_regions.transform_keys(&:to_sym).freeze
        @header_text = header_text
        @footer_text = footer_text
        @header_align = header_align.to_sym
        @footer_align = footer_align.to_sym
        @footnotes = Array(footnotes).freeze
        freeze
      end

      def body_region
        @regions[:body]
      end

      def width
        @page_size[0]
      end

      def height
        @page_size[1]
      end

      def each_box(&block)
        return enum_for(:each_box) unless block_given?

        @static_regions.each_value { |r| r.placed_boxes.each(&block) }
        @regions.each_value { |r| r.placed_boxes.each(&block) }
      end

      def ==(other)
        other.is_a?(self.class) &&
          number == other.number &&
          template_name == other.template_name &&
          template_role == other.template_role &&
          page_size == other.page_size &&
          regions == other.regions &&
          static_regions == other.static_regions &&
          header_text == other.header_text &&
          footer_text == other.footer_text &&
          footnotes == other.footnotes
      end

      alias eql? ==

      def hash
        [self.class, number, template_name, template_role, page_size,
         regions, static_regions, header_text, footer_text, footnotes].hash
      end
    end
  end
end
