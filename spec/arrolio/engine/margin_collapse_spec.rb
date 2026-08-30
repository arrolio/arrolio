# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Engine::MarginCollapse do
  describe '.overlap' do
    it 'is the min of the two margins' do
      expect(described_class.overlap(20, 12)).to eq(12.0)
      expect(described_class.overlap(12, 20)).to eq(12.0)
      expect(described_class.overlap(0, 7)).to eq(0.0)
    end
  end

  # The EFFECTIVE gap between the previous flowable's last ink and
  # the next flowable's first ink, simulated at the coordinate
  # level the way Engine#emit drives it:
  #
  #   y_top   = cursor (prev's consumed already advanced past its
  #             space_after)
  #   prev ink bottom = y_top - prev_after
  #   adjusted_y      = y_top + overlap
  #   curr first ink  = adjusted_y - (counts_margins ? before : 0)
  #
  # This table is the executable documentation of the margin
  # contract on Flowable: CSS max() holds only when before <=
  # prev_after AND the flowable counts its margins. The calibrated
  # flavor spacing rides these quirks.
  def effective_gap(prev_after, before, counts_margins)
    overlap = described_class.overlap(prev_after, before)
    prev_ink = -prev_after
    curr_ink = overlap - (counts_margins ? before : 0)
    curr_ink - prev_ink
  end

  it 'collapses to max when the incoming margin is smaller' do
    gap = effective_gap(20, 12, true)
    expect(gap).to eq(20) # max(20,12) - CSS-correct
  end

  it 'under-gaps when the incoming margin exceeds the previous' do
    gap = effective_gap(12, 20, true)
    expect(gap).to eq(4) # NOT max: 2*prev - before
    expect(gap).to be < 20
  end

  it 'DROPS the margin entirely for flowables that do not count margins' do
    # The engine adds nothing and the flowable subtracts nothing:
    # a non-counting flowable's space_before vanishes. This is why
    # spacing around notes travels as explicit Spacers.
    gap = effective_gap(0, 7, false)
    expect(gap).to eq(0)
  end

  it 'applies only the previous margin for non-counting flowables' do
    gap = effective_gap(12, 20, false)
    expect(gap).to eq(24) # overlap + prev_after; before vanishes
  end
end
