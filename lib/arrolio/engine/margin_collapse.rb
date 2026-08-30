# frozen_string_literal: true

module Arrolio
  module Engine
    # The engine's block-margin collapse rule — the ONE place the
    # spacing between consecutive flowables is decided.
    #
    # Current semantics (verified against the reference render):
    # the incoming flowable's consumption is reduced by
    # min(prev_space_after, curr_space_before). Because
    # TextFlowable counts its margins inside consumed while
    # ListFlowable-based flowables do not (see Flowable's margin
    # contract), the EFFECTIVE gap works out to CSS max() only
    # when curr.space_before <= prev.space_after; otherwise the
    # gap under-shoots. The calibrated flavor spacing rides these
    # quirks — unify only together with recalibration (TODO 96).
    module MarginCollapse
      module_function

      # The overlap subtracted from the incoming flowable's
      # consumption: the previous flowable already charged its
      # space-after into the cursor.
      def overlap(prev_space_after, curr_space_before)
        [prev_space_after.to_f, curr_space_before.to_f].min
      end
    end
  end
end
