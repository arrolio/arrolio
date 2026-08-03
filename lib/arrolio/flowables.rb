# frozen_string_literal: true

# Arrolio::Flowables — concrete Flowable subclasses.
module Arrolio
  module Flowables
    autoload :TextFlowable, 'arrolio/flowables/text_flowable'
    autoload :Spacer, 'arrolio/flowables/spacer'
    autoload :PageBreak, 'arrolio/flowables/page_break'
    autoload :HeadingFlowable, 'arrolio/flowables/heading_flowable'
    autoload :PageSequenceStart, 'arrolio/flowables/page_sequence_start'
    autoload :ListFlowable, 'arrolio/flowables/list_flowable'
    autoload :NoteFlowable, 'arrolio/flowables/note_flowable'
    autoload :ImageFlowable, 'arrolio/flowables/image_flowable'
    autoload :TocLineFlowable, 'arrolio/flowables/toc_line_flowable'
    autoload :TwoColumnBlock, 'arrolio/flowables/two_column_block'
    autoload :TableFlowable, 'arrolio/flowables/table_flowable'
  end
end
