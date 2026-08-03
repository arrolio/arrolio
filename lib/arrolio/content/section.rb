# frozen_string_literal: true

module Arrolio
  module Content
    class Section
      attr_reader :title, :level, :number, :id, :children, :style_id, :title_style_id

      def initialize(title: nil, level: 1, number: nil, id: nil,
                     children: [], style_id: :section_body, title_style_id: nil)
        @title = title
        @level = level.to_i
        @number = number
        @id = id
        @children = Array(children).freeze
        @style_id = style_id.to_sym
        @title_style_id = (title_style_id || default_title_style).to_sym
        freeze
      end

      def heading? = !@title.nil?

      def ==(other)
        other.is_a?(self.class) &&
          title == other.title && level == other.level && number == other.number &&
          id == other.id && children == other.children &&
          style_id == other.style_id && title_style_id == other.title_style_id
      end
      alias eql? ==

      def hash
        [self.class, title, level, number, id, children, style_id, title_style_id].hash
      end

      private

      def default_title_style = "heading_#{@level}"
    end
  end
end
