# frozen_string_literal: true

module Arrolio
  class Frame
    attr_reader :x, :y, :width, :height, :consumed

    def initialize(x:, y:, width:, height:, consumed: 0.0)
      @x = x.to_f
      @y = y.to_f
      @width = width.to_f
      @height = height.to_f
      @consumed = consumed.to_f
    end

    def remaining_height
      @height - @consumed
    end

    def full?
      remaining_height <= 0.5
    end

    def consume!(h)
      @consumed += h.to_f if h.to_f.positive?
      self
    end

    def cursor_y
      @y + @height - @consumed
    end

    def clone_empty
      self.class.new(x: @x, y: @y, width: @width, height: @height)
    end
  end
end
