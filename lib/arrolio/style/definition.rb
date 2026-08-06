# frozen_string_literal: true

module Arrolio
  module Style
    class Definition
      attr_reader :font_name, :font_size, :fill_color, :stroke_color,
                  :line_spacing, :align, :valign,
                  :margin_top, :margin_right, :margin_bottom, :margin_left,
                  :padding_top, :padding_right, :padding_bottom, :padding_left,
                  :character_spacing, :word_spacing, :line_break,
                  :keep_together, :page_break_before, :page_break_after,
                  :keep_with_next, :widows, :orphans, :parent,
                  :underline, :text_transform

      DEFAULTS = {
        font_name: 'Helvetica', font_size: 12.0,
        fill_color: nil, stroke_color: nil,
        line_spacing: 1.2, align: :left, valign: :top,
        margin_top: 0.0, margin_right: 0.0, margin_bottom: 0.0, margin_left: 0.0,
        padding_top: 0.0, padding_right: 0.0, padding_bottom: 0.0, padding_left: 0.0,
        character_spacing: 0.0, word_spacing: 0.0,
        line_break: :greedy,
        keep_together: false, page_break_before: false, page_break_after: false,
        keep_with_next: false, widows: 2, orphans: 2, parent: nil,
        underline: false, text_transform: nil
      }.freeze

      def initialize(**opts)
        merged = DEFAULTS.merge(opts.transform_keys(&:to_sym))
        @font_name = merged.fetch(:font_name).to_s
        @font_size = (merged.fetch(:font_size) || 0).to_f
        @fill_color = merged.fetch(:fill_color)
        @stroke_color = merged.fetch(:stroke_color)
        @line_spacing = (merged.fetch(:line_spacing) || 0).to_f
        @align = merged.fetch(:align).to_sym
        @valign = merged.fetch(:valign).to_sym
        @margin_top = (merged.fetch(:margin_top) || 0).to_f
        @margin_right = (merged.fetch(:margin_right) || 0).to_f
        @margin_bottom = (merged.fetch(:margin_bottom) || 0).to_f
        @margin_left = (merged.fetch(:margin_left) || 0).to_f
        @padding_top = (merged.fetch(:padding_top) || 0).to_f
        @padding_right = (merged.fetch(:padding_right) || 0).to_f
        @padding_bottom = (merged.fetch(:padding_bottom) || 0).to_f
        @padding_left = (merged.fetch(:padding_left) || 0).to_f
        @character_spacing = (merged.fetch(:character_spacing) || 0).to_f
        @word_spacing = (merged.fetch(:word_spacing) || 0).to_f
        @line_break = merged.fetch(:line_break).to_sym
        @keep_together = truthy?(merged.fetch(:keep_together))
        @page_break_before = truthy?(merged.fetch(:page_break_before))
        @page_break_after = truthy?(merged.fetch(:page_break_after))
        @keep_with_next = truthy?(merged.fetch(:keep_with_next))
        @widows = merged.fetch(:widows).to_i
        @orphans = merged.fetch(:orphans).to_i
        @parent = merged.fetch(:parent)
        @underline = truthy?(merged.fetch(:underline))
        @text_transform = merged.fetch(:text_transform)
        freeze
      end

      def with(**opts)
        self.class.new(**to_h, **opts.transform_keys(&:to_sym))
      end

      def space_before = @margin_top
      def space_after = @margin_bottom

      def ==(other)
        other.is_a?(self.class) && to_h == other.to_h
      end
      alias eql? ==

      def hash = to_h.hash

      def to_h
        {
          font_name: @font_name, font_size: @font_size,
          fill_color: @fill_color, stroke_color: @stroke_color,
          line_spacing: @line_spacing, align: @align, valign: @valign,
          margin_top: @margin_top, margin_right: @margin_right,
          margin_bottom: @margin_bottom, margin_left: @margin_left,
          padding_top: @padding_top, padding_right: @padding_right,
          padding_bottom: @padding_bottom, padding_left: @padding_left,
          character_spacing: @character_spacing, word_spacing: @word_spacing,
          line_break: @line_break, keep_together: @keep_together,
          page_break_before: @page_break_before, page_break_after: @page_break_after,
          keep_with_next: @keep_with_next, widows: @widows, orphans: @orphans,
          parent: @parent, underline: @underline, text_transform: @text_transform
        }
      end

      private

      def truthy?(v)
        case v
        when true, 'true', 'always' then true
        when Integer then v.positive?
        else false
        end
      end
    end
  end
end
