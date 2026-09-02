# frozen_string_literal: true

module Arrolio
  module Table
    # Pure table-split decision: which welded row groups fit the
    # page budget. The budget is the remaining page height minus
    # what travels with every part (the caption and the repeated
    # header rows). Groups are greedily packed while they fit; an
    # empty head means whole-move (the engine moves the entire
    # table to the next page).
    class SplitPolicy
      Result = Struct.new(:head_groups, :tail_groups, keyword_init: true) do
        def whole_move?
          head_groups.empty?
        end
      end

      # +groups+ Array of Arrays of row indexes (welded by rowspan).
      # +group_heights+ parallel Array of Float heights per group.
      # +budget+ Float height available for body groups.
      def initialize(groups:, group_heights:, budget:)
        @groups = groups
        @group_heights = group_heights
        @budget = budget.to_f
      end

      # Rows split IN ORDER: once a group does not fit, every
      # later group goes to the tail (a fitting later group must
      # never jump ahead of an overflowing earlier one - the
      # original greedy loop allowed exactly that reordering).
      def call
        head = []
        tail = []
        used = 0.0
        overflowing = false
        @groups.each do |group|
          height = group_height_for(group)
          overflowing ||= used + height > @budget
          (overflowing ? tail : head) << group
          used += height unless overflowing
        end
        Result.new(head_groups: head, tail_groups: tail)
      end

      private

      def group_height_for(group)
        @group_heights[group.first, group.length].sum
      end
    end
  end
end
