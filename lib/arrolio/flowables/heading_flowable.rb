# frozen_string_literal: true

module Arrolio
  module Flowables
    # A section heading: optional number + title text. Lives
    # separate from TextFlowable so the adapter and Engine can
    # recognise headings by type (for outline / TOC building).
    class HeadingFlowable < TextFlowable
      attr_reader :level, :number, :title, :id

      def initialize(title, level: 1, number: nil, id: nil,
                     style: Style::Definition.new, measurer: nil)
        full_text = number ? "#{number} #{title}" : title.to_s
        super([InlineRun.new(full_text, style: style)],
              style: style, measurer: measurer)
        @title = title
        @level = level.to_i
        @number = number
        @id = id
      end
    end
  end
end
