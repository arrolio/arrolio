# frozen_string_literal: true

module Arrolio
  module Content
    class List
      attr_reader :items, :kind, :style_id, :id

      def initialize(items = [], kind: :bullet, style_id: :list, id: nil)
        @items = items.map { |i| i.is_a?(Item) ? i : Item.new(i) }.freeze
        @kind = kind.to_sym
        @style_id = style_id.to_sym
        @id = id
        freeze
      end

      def ordered? = @kind == :ordered
      def bullet? = @kind == :bullet

      def ==(other)
        other.is_a?(self.class) &&
          items == other.items &&
          kind == other.kind &&
          style_id == other.style_id &&
          id == other.id
      end

      alias eql? ==

      def hash
        [self.class, items, kind, style_id, id].hash
      end

      class Item
        attr_reader :content, :marker

        def initialize(content, marker: nil)
          @content = Array(content).freeze
          @marker = marker
          freeze
        end

        def text
          @content.map do |node|
            node.is_a?(Paragraph) ? node.text : node.to_s
          end.join(' ')
        end

        def ==(other)
          other.is_a?(self.class) && content == other.content && marker == other.marker
        end

        alias eql? ==

        def hash
          [self.class, content, marker].hash
        end
      end
    end
  end
end
