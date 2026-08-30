# frozen_string_literal: true

require 'spec_helper'

# The parity metric's math, pinned. A month of ledger numbers
# (66.8 -> 68.92) ride on these functions; a silent change here
# invalidates the history.
RSpec.describe Arrolio::Harness::TextDiff do
  describe '.similarity' do
    it 'is 1.0 for identical text' do
      expect(described_class.similarity('The load cell output', 'the load cell output')).to eq(1.0)
    end

    it 'is 0.0 when either side is empty' do
      expect(described_class.similarity('', 'anything')).to eq(0.0)
      expect(described_class.similarity('anything', '')).to eq(0.0)
    end

    it 'is 1.0 when both are empty' do
      expect(described_class.similarity('', '')).to eq(1.0)
    end

    it 'is set-intersection over union, punctuation-insensitive' do
      # {load, cell} over {load, cell, mass} = 2/3
      expect(described_class.similarity('load, cell!', 'load cell mass')).to eq(2.0 / 3)
    end
  end

  describe '.paragraphs' do
    it 'splits on blank or whitespace-only lines and drops empties' do
      # a whitespace-ONLY line is a paragraph break: pdftotext
      # separates blocks with blank lines that sometimes carry a
      # stray space.
      expect(described_class.paragraphs("a\n\nb\n \nc")).to eq(['a', 'b', 'c'])
      expect(described_class.paragraphs("one\ntwo")).to eq(["one\ntwo"])
    end
  end

  describe '.match_paragraphs' do
    it 'pairs each ours-paragraph with its best unmatched theirs' do
      m = described_class.match_paragraphs("alpha beta\n\ngamma delta",
                                           "gamma delta\n\nalpha beta")
      expect(m.map { |x| x[:similarity] }).to all(eq(1.0))
    end

    it 'leaves theirs nil below the 0.3 threshold' do
      m = described_class.match_paragraphs('completely unrelated words', 'alpha beta gamma')
      expect(m.first[:theirs]).to be_nil
      expect(m.first[:similarity]).to eq(0.0)
    end

    it 'never reuses a theirs-paragraph' do
      m = described_class.match_paragraphs("alpha\n\nalpha", "alpha\n\nother words here")
      used = m.filter_map { |x| x[:theirs] }
      expect(used.length).to eq(used.uniq.length)
    end
  end
end
