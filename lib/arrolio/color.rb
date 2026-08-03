# frozen_string_literal: true

module Arrolio
  # Color value object. Parses CSS/XSL color specifications and
  # provides normalized RGB components for the renderer. Supports:
  # hex (#RGB, #RRGGBB), rgb(r,g,b), rgb(r%,g%,b%), named colors.
  #
  # The renderer calls +to_render+ to get the format pdfrb expects:
  # +Float+ for grayscale, +[:rgb, r, g, b]+ for color.
  class Color
    attr_reader :red, :green, :blue, :alpha

    # Named colors from the SVG/CSS specification subset commonly
    # used in XSL-FO documents.
    NAMED_COLORS = {
      'black' => [0, 0, 0],
      'white' => [255, 255, 255],
      'red' => [255, 0, 0],
      'green' => [0, 128, 0],
      'blue' => [0, 0, 255],
      'yellow' => [255, 255, 0],
      'cyan' => [0, 255, 255],
      'magenta' => [255, 0, 255],
      'gray' => [128, 128, 128],
      'grey' => [128, 128, 128],
      'silver' => [192, 192, 192],
      'maroon' => [128, 0, 0],
      'purple' => [128, 0, 128],
      'olive' => [128, 128, 0],
      'navy' => [0, 0, 128],
      'teal' => [0, 128, 128]
    }.freeze

    def initialize(red:, green:, blue:, alpha: 1.0)
      @red = clamp01(red.to_f)
      @green = clamp01(green.to_f)
      @blue = clamp01(blue.to_f)
      @alpha = clamp01(alpha.to_f)
      freeze
    end

    # Factory: parse any supported color specification.
    def self.parse(spec)
      return spec if spec.is_a?(self)
      return nil if spec.nil? || spec.to_s.empty?

      case spec.to_s.downcase
      when /\A#([0-9a-f])([0-9a-f])([0-9a-f])\z/
        new(red: Regexp.last_match(1).to_i(16) * 17 / 255.0,
            green: Regexp.last_match(2).to_i(16) * 17 / 255.0,
            blue: Regexp.last_match(3).to_i(16) * 17 / 255.0)
      when /\A#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})\z/
        new(red: Regexp.last_match(1).to_i(16) / 255.0,
            green: Regexp.last_match(2).to_i(16) / 255.0,
            blue: Regexp.last_match(3).to_i(16) / 255.0)
      when /\Argb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)\z/
        new(red: Regexp.last_match(1).to_i / 255.0,
            green: Regexp.last_match(2).to_i / 255.0,
            blue: Regexp.last_match(3).to_i / 255.0)
      when /\Argb\(\s*([\d.]+)%\s*,\s*([\d.]+)%\s*,\s*([\d.]+)%\s*\)\z/
        new(red: Regexp.last_match(1).to_f / 100.0,
            green: Regexp.last_match(2).to_f / 100.0,
            blue: Regexp.last_match(3).to_f / 100.0)
      else
        parse_named(spec.to_s.downcase)
      end
    end

    def self.parse_named(name)
      return nil unless NAMED_COLORS.key?(name)

      r, g, b = NAMED_COLORS[name]
      new(red: r / 255.0, green: g / 255.0, blue: b / 255.0)
    end
    private_class_method :parse_named

    # Returns the format pdfrb's canvas expects: +[:rgb, r, g, b]+.
    def to_render
      [:rgb, @red, @green, @blue]
    end

    def grayscale?
      @red == @green && @green == @blue
    end

    def to_grayscale_float
      (0.299 * @red) + (0.587 * @green) + (0.114 * @blue)
    end

    def ==(other)
      other.is_a?(self.class) &&
        red == other.red && green == other.green &&
        blue == other.blue && alpha == other.alpha
    end
    alias eql? ==

    def hash
      [self.class, red, green, blue, alpha].hash
    end

    private

    def clamp01(v)
      v.clamp(0.0, 1.0)
    end
  end
end
