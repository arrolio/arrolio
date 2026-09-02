# frozen_string_literal: true

require 'spec_helper'

# The pure table-split decision, tested at its own interface:
# which welded row groups fit the budget. No boxes, no emission.
RSpec.describe Arrolio::Table::SplitPolicy do
  def policy(groups, heights, budget)
    described_class.new(groups: groups, group_heights: heights,
                        budget: budget).call
  end

  it 'packs every group when all fit' do
    result = policy([[0], [1], [2]], [20.0, 20.0, 20.0], 60.0)
    expect(result.head_groups).to eq([[0], [1], [2]])
    expect(result.tail_groups).to eq([])
    expect(result).not_to be_whole_move
  end

  it 'splits when a group would overflow the budget' do
    result = policy([[0], [1], [2]], [20.0, 20.0, 20.0], 45.0)
    expect(result.head_groups).to eq([[0], [1]])
    expect(result.tail_groups).to eq([[2]])
  end

  it 'signals a whole move when even the first group does not fit' do
    result = policy([[0], [1]], [30.0, 10.0], 20.0)
    expect(result).to be_whole_move
    expect(result.tail_groups).to eq([[0], [1]])
  end

  it 'measures multi-row welded groups by their summed height' do
    # group [0,1] welded by a rowspan: 10+20 = 30pt; single [2]: 10pt
    result = policy([[0, 1], [2]], [10.0, 20.0, 10.0], 40.0)
    expect(result.head_groups).to eq([[0, 1], [2]])

    tight = policy([[0, 1], [2]], [10.0, 20.0, 10.0], 35.0)
    expect(tight.head_groups).to eq([[0, 1]])
    expect(tight.tail_groups).to eq([[2]])
  end

  it 'never reorders: a fitting later group does not jump an overflowing earlier one' do
    # The original greedy packed [2] into the head after [1]
    # overflowed - rows rendered out of order. The policy splits
    # strictly in document order.
    result = policy([[0], [1], [2]], [5.0, 10.0, 5.0], 10.0)
    expect(result.head_groups).to eq([[0]])
    expect(result.tail_groups).to eq([[1], [2]])
  end
end
